/** Bounded recovery for an existing authenticated session. Credentials remain
 * in GameConnection; every retry uses the normal server login handshake. */
import type { ConnectionStatus } from './connection';

export function isSessionRejection(status: ConnectionStatus, command: string, data: unknown): boolean {
  if (command !== 'ErrorDlg' && command !== 'ErrorMsg') return false;
  // Native admission failures and explicit account takeover terminate the
  // session. Room errors can arrive on an otherwise usable connection.
  return status.kind !== 'online' || data === 'others logged in again with this name';
}

export interface RecoveryClock {
  set(callback: () => void, delay: number): unknown;
  clear(handle: unknown): void;
  random(): number;
}
const browserClock: RecoveryClock = {
  set: (callback, delay) => setTimeout(callback, delay),
  clear: (handle) => clearTimeout(handle as ReturnType<typeof setTimeout>),
  random: () => Math.random(),
};
export class SessionRecovery {
  private timer: unknown;
  private revision = 0;
  private attempts = 0;
  constructor(private callbacks: {
    waiting(attempt: number): void;
    connect(): void;
    timeout(): void;
    exhausted(): void;
  }, private clock: RecoveryClock = browserClock) {}
  private clear() {
    ++this.revision;
    if (this.timer !== undefined) this.clock.clear(this.timer);
    this.timer = undefined;
  }
  lost() {
    this.clear();
    if (this.attempts >= 5) { this.callbacks.exhausted(); return; }
    const attempt = ++this.attempts;
    const revision = this.revision;
    this.callbacks.waiting(attempt);
    if (revision !== this.revision) return;
    const delay = Math.min(10000, 500 * 2 ** (attempt - 1)) * (0.8 + 0.4 * this.clock.random());
    this.timer = this.clock.set(() => {
      this.timer = undefined;
      if (revision !== this.revision) return;
      // Covers a socket or authentication handshake which never completes.
      this.timer = this.clock.set(() => {
        this.timer = undefined;
        if (revision === this.revision) this.callbacks.timeout();
      }, 90000);
      this.callbacks.connect();
    }, delay);
  }
  restored() { this.clear(); this.attempts = 0; }
  stop() { this.clear(); this.attempts = 0; }
}
