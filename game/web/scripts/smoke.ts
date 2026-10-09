// Smoke test: boot the FreeKill client Lua inside wasmoon under Node.
//
//   npx tsx scripts/smoke.ts <upstream-dir> [host:port] [user] [password]
//
// <upstream-dir> must contain freekill-core/, utility/, hegemony/ checkouts.
// With host:port it also logs in to a live freekill-asio over TCP.
import fs from 'node:fs';
import path from 'node:path';
import net from 'node:net';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { GameConnection } from '../src/engine/connection';

const upstream = process.argv[2];
if (!upstream) throw new Error('usage: smoke.ts <upstream-dir> [host:port] [user] [password]');

const files = new Map<string, Uint8Array>();
for (const pkg of ['freekill-core', 'utility', 'hegemony']) {
  const root = path.join(upstream, pkg);
  const walk = (d: string) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      if (e.name === '.git') continue;
      const f = path.join(d, e.name);
      if (e.isDirectory()) walk(f);
      else if (/\.(lua|json)$/i.test(e.name)) {
        files.set(`packages/${pkg}/${path.relative(root, f).split(path.sep).join('/')}`, fs.readFileSync(f));
      }
    }
  };
  walk(root);
}
console.log(`mounted ${files.size} files`);

const target = process.argv[3];
const t0 = Date.now();

if (!target) {
  const rt = new LuaRuntime({
    files,
    callbacks: {
      send: (k, c, h) => console.log('send', k, c, h.length / 2, 'bytes'),
      ui: (c, d) => console.log('ui', c, JSON.stringify(d)?.slice(0, 200)),
      setup: () => console.log('setup requested'),
    },
  });
  await rt.start();
  console.log(`booted in ${Date.now() - t0} ms`);
  console.log('translate test:', rt.call('Translate', 'slash'), rt.call('Translate', 'caocao'));
  console.log('modes:', JSON.stringify(rt.call('GetGameModes')).slice(0, 400));
  process.exit(0);
}

const [host, port] = target.split(':');
const conn = new GameConnection({
  files,
  username: process.argv[4] ?? 'webtest',
  password: process.argv[5] ?? 'webtest-pass',
  md5: process.env.FK_MD5 ?? '',
  uuid: 'web-smoke-0001',
  openSocket: (h) => {
    const s = net.createConnection({ host, port: Number(port) });
    s.on('data', (b) => h.onData(new Uint8Array(b)));
    s.on('close', () => h.onClose('tcp closed'));
    s.on('error', (e) => h.onClose(e.message));
    return { send: (b) => s.write(b), close: () => s.destroy() };
  },
  onUi: (c, d) => console.log('ui', c, JSON.stringify(d)?.slice(0, 300)),
  onStatus: (s) => console.log('status', s),
});
await conn.start();
setTimeout(() => {
  console.log('done');
  process.exit(0);
}, 15000);
