// SPDX-License-Identifier: GPL-3.0-or-later
//
// Runs the unmodified FreeKill client Lua (freekill-core + extension
// packages) inside wasmoon (Lua 5.4 compiled to WebAssembly).

import { LuaFactory, type LuaEngine } from 'wasmoon';
import { HOST_LUA } from './hostLua';

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
}

type FS = {
  chdir(p: string): void;
  cwd(): string;
  readdir(p: string): string[];
  stat(p: string): { mode: number };
  isDir(mode: number): boolean;
  mkdirTree?(p: string): void;
  mkdir(p: string): void;
  writeFile(p: string, d: Uint8Array | string): void;
  analyzePath(p: string): { exists: boolean };
};

export class LuaRuntime {
  private engine!: LuaEngine;
  private fs!: FS;
  private recvFn!: (cmd: string, hex: string, isRequest: boolean) => void;
  private evalFn!: (code: string) => string;
  private callFn!: (name: string, argsJson: string) => string;

  constructor(private opts: LuaRuntimeOptions) {}

  async start(): Promise<void> {
    const factory = new LuaFactory(this.opts.wasmUrl);
    const wasm = await factory.getLuaModule();
    this.fs = (wasm as unknown as { module: { FS: FS } }).module.FS;

    const files = this.opts.files instanceof Map ? this.opts.files : new Map(Object.entries(this.opts.files));
    const dirs = new Set<string>();
    const mkdirp = (dir: string) => {
      if (dirs.has(dir) || dir === '' || dir === '/') return;
      const parent = dir.slice(0, dir.lastIndexOf('/'));
      mkdirp(parent);
      if (!this.fs.analyzePath(dir).exists) this.fs.mkdir(dir);
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
      openStandardLibs: true,
      injectObjects: false,
      enableProxy: false,
    });

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
      exists: (p: string) => fs.analyzePath(resolve(p)).exists,
      isDir: (p: string) => {
        try {
          return fs.isDir(fs.stat(resolve(p)).mode);
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
    this.engine.global.set('__js', js);

    await this.engine.doString(HOST_LUA);

    // Same boot order as the native client: load the engine from the
    // freekill-core directory, then the client layer (which cds back to root).
    fs.chdir(`${GAME_ROOT}/packages/freekill-core`);
    await this.engine.doString('dofile "lua/freekill.lua"');
    await this.engine.doString('dofile "lua/client/client.lua"');
    await this.engine.doString('CreateLuaClient(__host_client)');

    this.recvFn = this.engine.global.get('__host_recv');
    this.evalFn = this.engine.global.get('__host_eval');
    this.callFn = this.engine.global.get('__host_call');
  }

  /** Feed a packet from the server into the Lua client. */
  receive(command: string, hex: string, isRequest: boolean) {
    this.recvFn(command, hex, isRequest);
  }

  /** Evaluate a Lua chunk (should `return` a value) and get it back as JSON. */
  eval<T = unknown>(code: string): T {
    return JSON.parse(this.evalFn(code)) as T;
  }

  /** Call a global Lua function (e.g. UpdateRequestUI, Translate). */
  call<T = unknown>(name: string, ...args: unknown[]): T {
    return JSON.parse(this.callFn(name, JSON.stringify(args))) as T;
  }

  close() {
    this.engine?.global.close();
  }
}

function defaultLog(level: string, msg: string) {
  const f = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
  f(`[lua:${level}] ${msg}`);
}
