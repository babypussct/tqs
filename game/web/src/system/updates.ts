import { create } from 'zustand';
import { BUILD, parseBuild, type BuildInfo } from './buildInfo';
import { assertManifest, type GatewayManifest } from '../engine/bundle';

type BundleIdentity = Pick<GatewayManifest, 'md5' | 'bundleHash'>;
export interface UpdateState {
  pending: boolean; latest: BuildInfo | null; reason: string;
  checking: boolean; applying: boolean; error: string | null; checkedAt: number | null;
}
const initial: UpdateState = { pending: false, latest: null, reason: '', checking: false, applying: false, error: null, checkedAt: null };
export const useUpdateStore = create<UpdateState>(() => ({ ...initial }));

export async function fetchFresh(url: string): Promise<Response> {
  const response = await fetch(url, { cache: 'no-store', signal: AbortSignal.timeout(8000) });
  if (!response.ok) throw new Error('Update endpoint unavailable');
  return response;
}

/** No reload or controllerchange listener can interrupt a running match. */
export class UpdateCoordinator {
  private flight: Promise<boolean> | null = null;
  private flightIdentity: string | null = null;
  private registration: ServiceWorkerRegistration | undefined;
  private bundleChanged = false;
  private listeners = new Set<() => void>();
  constructor(private options: {
    gateway: string; build?: BuildInfo; webChecks: boolean;
    manifest: () => BundleIdentity | null; playing: () => boolean;
    state?: typeof useUpdateStore; fetch?: typeof fetchFresh; reload?: () => void;
  }) {}
  private get state() { return this.options.state ?? useUpdateStore; }
  watchRegistration(registration: ServiceWorkerRegistration): () => void {
    this.registration = registration;
    const inspect = () => {
      // A waiting worker can belong to the build this page already loaded
      // over the network. Only fresh release metadata establishes a change.
      if (registration.waiting && registration.active) void this.check();
    };
    const watch = () => {
      const worker = registration.installing;
      if (!worker) return;
      const changed = () => { if (worker.state === 'installed') inspect(); };
      worker.addEventListener('statechange', changed);
      this.listeners.add(() => worker.removeEventListener('statechange', changed));
      changed();
    };
    registration.addEventListener('updatefound', watch);
    watch(); inspect();
    return () => {
      registration.removeEventListener('updatefound', watch);
      this.listeners.forEach((remove) => remove()); this.listeners.clear();
      if (this.registration === registration) this.registration = undefined;
    };
  }
  async check(): Promise<boolean> {
    if (this.flight) {
      const coveredIdentity = this.flightIdentity;
      const result = await this.flight;
      const loaded = this.options.manifest();
      const currentIdentity = loaded ? `${loaded.bundleHash}:${loaded.md5}` : null;
      // A boot check that started before Lua loaded cannot satisfy an entry gate.
      if (currentIdentity !== coveredIdentity) return this.check();
      return result;
    }
    const loaded = this.options.manifest();
    this.flightIdentity = loaded ? `${loaded.bundleHash}:${loaded.md5}` : null;
    this.flight = this.performCheck().finally(() => { this.flight = null; });
    return this.flight;
  }
  private async performCheck(): Promise<boolean> {
    this.state.setState({ checking: true, error: null });
    const fresh = this.options.fetch ?? fetchFresh;
    let ok = true;
    // Read the loaded identity AFTER the response: boot may finish while the request is in flight.
    const checks: Promise<void>[] = [];
    if (this.options.webChecks) checks.push((async () => {
      const latest = parseBuild(await (await fresh(`/version.json?t=${Date.now()}`)).json());
      this.state.setState({ latest });
    })());
    if (this.options.manifest()) checks.push((async () => {
      const raw: unknown = await (await fresh(`${this.options.gateway}/manifest.json?t=${Date.now()}`)).json();
      assertManifest(raw);
      const loaded = this.options.manifest();
      this.bundleChanged = !!loaded && (raw.bundleHash.toLowerCase() !== loaded.bundleHash.toLowerCase() || raw.md5.toLowerCase() !== loaded.md5.toLowerCase());
    })());
    else this.bundleChanged = false;
    const results = await Promise.allSettled(checks);
    if (results.some((r) => r.status === 'rejected')) {
      ok = false;
      this.state.setState({ error: 'Chưa kiểm tra được phiên bản. Kiểm tra mạng và thử lại.' });
    }
    // Worker update failure alone must not claim a new release or prevent online play.
    if (this.registration) void this.registration.update().catch(() => {});
    const latest = this.state.getState().latest;
    const webChanged = this.options.webChecks && !!latest && latest.buildId !== (this.options.build ?? BUILD).buildId;
    this.state.setState({ pending: webChanged || this.bundleChanged,
      reason: webChanged ? 'Có bản giao diện mới.' : this.bundleChanged ? 'Gói dữ liệu chiến trường đã thay đổi.' : '',
      checking: false, checkedAt: ok ? Date.now() : this.state.getState().checkedAt });
    return ok && !this.state.getState().pending;
  }
  async beforeEntry(): Promise<void> {
    if (!await this.check()) throw new Error(this.state.getState().pending
      ? 'Có bản mới. Vui lòng cập nhật trước khi vào chiến trường.'
      : 'Chưa kiểm tra được phiên bản. Kiểm tra mạng và thử lại.');
  }
  async apply(manual = false): Promise<void> {
    if (this.options.playing() || this.state.getState().applying) return;
    this.state.setState({ applying: true, error: null });
    try {
      // Verify reachability before deleting the offline shell. Auth storage is never touched.
      await this.check();
      if (this.state.getState().error) throw new Error('offline');
      if (!manual && !this.state.getState().pending) return;
      if (this.options.playing()) return;
      const registration = this.registration;
      if (registration) {
        await registration.update();
        const worker = registration.installing ?? registration.waiting;
        if (worker && worker.state !== 'activated' && worker.state !== 'redundant') {
          await new Promise<void>((resolve, reject) => {
            const timer = setTimeout(() => done(new Error('Worker timeout')), 30000);
            const done = (error?: Error) => {
              clearTimeout(timer); worker.removeEventListener('statechange', changed);
              error ? reject(error) : resolve();
            };
            const changed = () => {
              if (this.options.playing()) return done(new Error('Match started'));
              if (worker.state === 'installed') worker.postMessage({ type: 'SKIP_WAITING' });
              if (worker.state === 'activated') done();
              if (worker.state === 'redundant') done(new Error('Worker failed'));
            };
            worker.addEventListener('statechange', changed); changed();
          });
        }
      }
      if (this.options.playing()) return;
      if ('caches' in globalThis) {
        for (const key of await caches.keys()) if (key.startsWith('tqs-shell-')) await caches.delete(key);
      }
      if (registration?.active) await new Promise<void>((resolve, reject) => {
        const channel = new MessageChannel();
        const timer = setTimeout(() => { channel.port1.close(); reject(new Error('Cache refresh timeout')); }, 60000);
        channel.port1.onmessage = (event) => {
          clearTimeout(timer); channel.port1.close();
          event.data?.ok ? resolve() : reject(new Error('Cache refresh failed'));
        };
        registration.active!.postMessage({ type: 'REFRESH_SHELL' }, [channel.port2]);
      });
      if (this.options.playing()) return;
      if (this.options.reload) this.options.reload();
      else {
        const url = new URL(location.href);
        url.searchParams.set('tqs-update', String(Date.now()));
        location.replace(url.href);
      }
    } catch {
      this.state.setState({ error: 'Chưa cập nhật được. Giữ kết nối mạng và bấm thử lại.' });
    } finally { this.state.setState({ applying: false }); }
  }
}
