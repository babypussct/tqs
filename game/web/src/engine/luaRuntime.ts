// SPDX-License-Identifier: GPL-3.0-or-later
//
// Runs the unmodified FreeKill client Lua (freekill-core + extension
// packages) inside wasmoon (Lua 5.4 compiled to WebAssembly).

import { LuaFactory, decorateFunction, type LuaEngine, type LuaThread } from 'wasmoon';
import { HOST_LUA } from './hostLua';
import { VI_ADDITIONS } from './vietnamese';

export const GAME_ROOT = '/fk';

export interface LuaHostCallbacks {
  send(kind: 'notify' | 'reply', command: string, hex: string): void;
  ui(command: string, data: unknown): void;
  setup(pubkey: string): void;
  serverLag?(serverMs: number): void;
  log?(level: string, msg: string): void;
}

export interface LuaRuntimeOptions {
  /** Map of path (relative to game root, e.g. "packages/freekill-core/lua/freekill.lua") -> content. */
  files: Map<string, Uint8Array> | Record<string, Uint8Array>;
  callbacks: LuaHostCallbacks;
  /** Client language, e.g. "vi_VN". Written to freekill.client.config.json. */
  language?: string;
  /** Optional custom URL of wasmoon's glue.wasm (browser builds). */
  wasmUrl?: string;
  /** Enable bounded, numeric-only memory/callback diagnostics for test runs. */
  telemetry?: boolean;
}

export interface LuaTelemetrySample {
  elapsedMs: number;
  wasmBytes: number;
  luaHeapKiB: number | null;
  callbacksTotal: number;
  callbacksActive: number;
  callbacksPeak: number;
}

export interface LuaTelemetry {
  startedAt: string;
  samples: LuaTelemetrySample[];
  callbackCounts: Record<string, number>;
  callbacksTotal: number;
  callbacksActive: number;
  callbacksPeak: number;
  sampleErrors: number;
  closedAt?: string;
}

type FS = {
  chdir(p: string): void;
  cwd(): string;
  readdir(p: string): string[];
  stat(p: string): { mode: number };
  mkdirTree?(p: string): void;
  mkdir(p: string): void;
  writeFile(p: string, d: Uint8Array | string): void;
};

function pathExists(fs: FS, pathname: string): boolean {
  try {
    fs.stat(pathname);
    return true;
  } catch (error) {
    // Only a missing path means false. Propagate permission / IO failures.
    if (typeof error === 'object' && error !== null && 'code' in error && error.code === 'ENOENT') {
      return false;
    }
    throw error;
  }
}

export class LuaRuntime {
  private engine!: LuaEngine;
  private fs!: FS;
  private callbackThread: LuaThread | null = null;
  private telemetry: LuaTelemetry | null = null;
  private telemetryTimer: ReturnType<typeof setInterval> | null = null;
  private wasmHeap: { HEAPU8: Uint8Array } | null = null;


  constructor(private opts: LuaRuntimeOptions) {}

  async start(): Promise<void> {
    const factory = new LuaFactory(this.opts.wasmUrl);
    const wasm = await factory.getLuaModule();
    this.wasmHeap = (wasm as unknown as { module: { HEAPU8: Uint8Array } }).module;
    this.fs = (wasm as unknown as { module: { FS: FS } }).module.FS;

    const files = this.opts.files instanceof Map ? this.opts.files : new Map(Object.entries(this.opts.files));
    const dirs = new Set<string>();
    const mkdirp = (dir: string) => {
      if (dirs.has(dir) || dir === '' || dir === '/') return;
      const parent = dir.slice(0, dir.lastIndexOf('/'));
      mkdirp(parent);
      if (!pathExists(this.fs, dir)) this.fs.mkdir(dir);
      dirs.add(dir);
    };
    for (const [rel, content] of files) {
      const full = `${GAME_ROOT}/${rel}`;
      mkdirp(full.slice(0, full.lastIndexOf('/')));
      this.fs.writeFile(full, content);
    }
    mkdirp(GAME_ROOT);
    this.fs.writeFile(
      `${GAME_ROOT}/freekill.client.config.json`,
      JSON.stringify({ language: this.opts.language ?? 'vi_VN' }),
    );

    this.engine = await factory.createEngine({
      traceAllocations: import.meta.env?.VITE_LUA_DIAGNOSTICS === '1',
      openStandardLibs: true,
      injectObjects: false,
      enableProxy: false,
    });

    // Wasmoon 1.16 exposes the LuaWasm used by the engine as `cmodule`.
    // A separate module would silently lose files mounted before engine boot.
    if ((this.engine as unknown as { cmodule?: unknown }).cmodule !== wasm) {
      throw new Error('Wasmoon engine and mounted filesystem use different modules');
    }

    const diagnostic = import.meta.env?.VITE_LUA_DIAGNOSTICS === '1';
    const telemetryEnabled = this.opts.telemetry === true ||
      (globalThis as { __tqsEnableLuaTelemetry?: boolean }).__tqsEnableLuaTelemetry === true;
    if (telemetryEnabled) {
      this.telemetry = { startedAt: new Date().toISOString(), samples: [], callbackCounts: Object.create(null) as Record<string, number>,
        callbacksTotal: 0, callbacksActive: 0, callbacksPeak: 0, sampleErrors: 0 };
      // Exposed only after explicit opt-in; contains counters and heap sizes, never packets or credentials.
      (globalThis as { __tqsLuaTelemetry?: LuaTelemetry }).__tqsLuaTelemetry = this.telemetry;
    }
    if (diagnostic) this.engine.global.setMemoryMax(128 * 1024 * 1024);
    const cb = this.opts.callbacks;
    const fs = this.fs;
    const resolve = (p: string) => p;
    const js = {
      cd: (p: string) => {
        try {
          fs.chdir(resolve(p));
        } catch {
          cb.log?.('warn', `cd failed: ${p}`);
        }
      },
      pwd: () => fs.cwd(),
      ls: (p: string) => {
        try {
          return fs
            .readdir(resolve(p))
            .filter((n) => n !== '.' && n !== '..')
            .join('\n');
        } catch {
          return '';
        }
      },
      exists: (p: string) => pathExists(fs, resolve(p)),
      isDir: (p: string) => {
        try {
          // Wasmoon 1.16 exposes FS.stat(), but not Emscripten's FS.isDir().
          // Decode the POSIX file-type bits (S_IFMT / S_IFDIR) directly.
          return (fs.stat(resolve(p)).mode & 0o170000) === 0o040000;
        } catch {
          return false;
        }
      },
      nowUs: () => Math.floor((performance.timeOrigin + performance.now()) * 1000),
      log: (level: string, msg: string) => (cb.log ?? defaultLog)(level, msg),
      send: (kind: 'notify' | 'reply', command: string, hex: string) => cb.send(kind, command, hex),
      ui: (command: string, json: string) => {
        let data: unknown = null;
        try {
          data = JSON.parse(json);
        } catch {
          data = json;
        }
        cb.ui(command, data);
      },
      setup: (pubkey: string) => cb.setup(pubkey),
      serverLag: (ms: number) => cb.serverLag?.(ms),
    };
    // A Lua coroutine can call into JS while the main state is its resumer.
    // Reentrant UI queries must use the calling coroutine's C stack, rather
    // than push a second call onto the suspended main state's active frame.
    if (diagnostic) Object.assign(js, { traceLine: (source: string, line: number) => {
      const target = globalThis as unknown as { __tqsLuaLocation?: {source:string;line:number} };
      target.__tqsLuaLocation = {source,line};
    } });
    const bound = Object.fromEntries(Object.entries(js).map(([name, target]) => [name,
      decorateFunction((thread: LuaThread, ...args: unknown[]) => {
        const previous = this.callbackThread;
        this.callbackThread = thread;
        const metrics = this.telemetry;
        if (metrics) {
          metrics.callbacksTotal++;
          metrics.callbacksActive++;
          metrics.callbacksPeak = Math.max(metrics.callbacksPeak, metrics.callbacksActive);
          metrics.callbackCounts[name] = (metrics.callbackCounts[name] ?? 0) + 1;
        }
        try { return (target as (...values: unknown[]) => unknown)(...args); }
        finally {
          if (metrics) metrics.callbacksActive--;
          this.callbackThread = previous;
        }
      }, { receiveThread: true }),
    ]));
    this.engine.global.set('__js', bound);

    await this.engine.doString(HOST_LUA);

    // Same boot order as the native client: load the engine from the
    // freekill-core directory, then the client layer (which cds back to root).
    fs.chdir(`${GAME_ROOT}/packages/freekill-core`);
    await this.engine.doString('dofile "lua/freekill.lua"');
    await this.engine.doString('dofile "lua/client/client.lua"');
    await this.engine.doString('CreateLuaClient(__host_client)');

    this.call('__web_init_display_translations', VI_ADDITIONS);
    if (diagnostic) this.eval('debug.sethook(function(_, line) local info = debug.getinfo(2, "S"); __js.traceLine(info.short_src, line or 0) end, "l"); return true');
    if (this.telemetry) {
      this.sampleTelemetry();
      this.telemetryTimer = setInterval(() => this.sampleTelemetry(), 2000);
    }
  }

  /** Sampling occurs outside active JS callbacks; Emscripten refreshes HEAPU8 after memory.grow. */
  sampleTelemetry(): void {
    const metrics = this.telemetry;
    if (!metrics || !this.engine || this.engine.global.isClosed() || metrics.callbacksActive > 0) return;
    let luaHeapKiB: number | null = null;
    try { luaHeapKiB = this.eval<number>('return collectgarbage("count")'); }
    catch { metrics.sampleErrors++; }
    metrics.samples.push({ elapsedMs: Date.now() - Date.parse(metrics.startedAt),
      wasmBytes: this.wasmHeap?.HEAPU8.byteLength ?? 0, luaHeapKiB,
      callbacksTotal: metrics.callbacksTotal, callbacksActive: metrics.callbacksActive, callbacksPeak: metrics.callbacksPeak });
    if (metrics.samples.length > 1800) metrics.samples.shift();
  }

  getTelemetry(): LuaTelemetry | null { return this.telemetry; }

  /** Feed a packet from the server into the Lua client. */
  receive(command: string, hex: string, isRequest: boolean) {
    this.invoke('__host_recv', [command, hex, isRequest]);
  }

  /** Evaluate a Lua chunk (should `return` a value) and get it back as JSON. */
  eval<T = unknown>(code: string): T {
    return JSON.parse(this.invoke('__host_eval', [code]) as string) as T;
  }

  /** Call a global Lua function (e.g. UpdateRequestUI, Translate). */
  call<T = unknown>(name: string, ...args: unknown[]): T {
    return JSON.parse(this.invoke('__host_call', [name, JSON.stringify(args)]) as string) as T;
  }

  /** Use a protected, balanced call on the owning Lua state. Wasmoon's JS
   * function wrappers allocate a transient coroutine for every invocation;
   * nested UI callbacks can otherwise mix coroutine lifetimes and GC. */
  private invoke(name: string, args: unknown[]): unknown {
    const state = this.callbackThread ?? this.engine.global;
    const top = state.getTop();
    try {
      state.lua.lua_getglobal(state.address, name);
      for (const arg of args) state.pushValue(arg);
      state.assertOk(state.lua.lua_pcallk(state.address, args.length, 1, 0, 0, null));
      return state.getValue(-1);
    } finally {
      state.setTop(top);
    }
  }

  close() {
    if (this.telemetryTimer) clearInterval(this.telemetryTimer);
    this.telemetryTimer = null;
    if (this.telemetry && !this.telemetry.closedAt) this.telemetry.closedAt = new Date().toISOString();
    const state = this.engine?.global;
    if (!state || state.isClosed()) return;
    const lua = state.lua;
    const unref = lua.luaL_unref;
    // Wasmoon 1.16 closes the Lua state before its function extension calls
    // luaL_unref on the callback coroutine. That address is already freed.
    // During teardown the registry dies with the VM; never access it afterward.
    lua.luaL_unref = (...args) => { if (!state.isClosed()) unref(...args); };
    try { state.close(); }
    finally { lua.luaL_unref = unref; }
  }
}

function defaultLog(level: string, msg: string) {
  const f = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
  f(`[lua:${level}] ${msg}`);
}
