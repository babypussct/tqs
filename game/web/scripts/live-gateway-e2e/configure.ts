/** Prepare an isolated local snapshot and a dedicated test account config.
 * The probe fails MD5 deliberately: upstream checks MD5 BEFORE registration.
 * No live services, package versions or room state are changed here. */
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { randomBytes, randomUUID } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import forge from 'node-forge';
import { LuaRuntime } from '../../src/engine/luaRuntime';
import { CLIENT_NOTIFY, PacketStream, encodePacket, encodeTextArray, toHex } from '../../src/engine/packet';
import { buildSnapshot, PACKAGES } from './snapshot';
import { packageSpec } from '../upstream-packages';

const repo = fileURLToPath(new URL('../../../../', import.meta.url));
const host = process.env.TQS_LIVE_HOST ?? '161.33.209.212';
const port = Number(process.env.TQS_LIVE_PORT ?? 9527);
assert.ok(/^[\w.:-]+$/.test(host) && Number.isInteger(port) && port > 0 && port <= 65535,
  'Invalid live server endpoint');
const source = path.resolve(process.env.TQS_PACKAGE_SOURCE ?? path.join(repo, 'scratch/upstream'));
const config = process.env.TQS_LIVE_CONFIG ?? path.join(os.homedir(), '.codex/secrets/tqs-live-test.env');
// Never replace an existing account/password or silently create a second one.
assert.ok(!existsSync(config), 'Test config already exists; use test:e2e:login to reuse it');

const files = new Map<string, Uint8Array>();
function load(dir: string, relative: string) {
  // Only Lua/JSON are needed to decode the binary package summary in Wasmoon.
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.name === '.git') continue;
    if (entry.isDirectory()) load(full, `${relative}/${entry.name}`);
    else if (entry.isFile() && /\.(lua|json)$/.test(entry.name))
      files.set(`${relative}/${entry.name}`, readFileSync(full));
  }
}
for (const pkg of PACKAGES) load(path.join(source, packageSpec(pkg).sourceDirectory), `packages/${pkg}`);
const lua = new LuaRuntime({ files, callbacks: { send() {}, ui() {}, setup() {} } });
await lua.start();
type Package = { name: string; hash: string; url: string };
let summary: Package[];
try {
  summary = await new Promise<Package[]>((resolve, reject) => {
    const stream = new PacketStream();
    const socket = net.createConnection({ host, port });
    let finished = false;
    const finish = (error?: Error, value?: Package[]) => {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      socket.destroy();
      if (error) reject(error); else resolve(value!);
    };
    const timer = setTimeout(() => finish(new Error('Package probe timed out')), 15_000);
    socket.on('error', () => finish(new Error('Package probe connection failed')));
    socket.on('close', () => finish(new Error('Server closed before package summary')));
    socket.on('data', (bytes) => {
      try {
        for (const packet of stream.push(bytes)) {
          if (packet.command === 'NetworkDelayTest') {
            const key = lua.eval<string>(`return cbor.decode(__host_hex2bin('${toHex(packet.data)}'))`);
            const publicKey = forge.pki.publicKeyFromPem(key);
            const cipher = publicKey.encrypt(`${randomBytes(16).toString('hex')}probe-only`, 'RSAES-PKCS1-V1_5');
            socket.write(encodePacket({ requestId: -2, type: CLIENT_NOTIFY, command: 'Setup',
              data: encodeTextArray(['tqs-package-probe', Uint8Array.from(cipher, (c) => c.charCodeAt(0)),
                '00000000000000000000000000000000', '0.5.25', randomUUID()]) }));
          } else if (packet.command === 'UpdatePackage') {
            finish(undefined, lua.eval<Package[]>(`return cbor.decode(__host_hex2bin('${toHex(packet.data)}'))`));
          }
        }
      } catch { finish(new Error('Unable to decode server package summary')); }
    });
  });
} finally { lua.close(); }
assert.deepEqual(summary.map((pkg) => pkg.name).sort(), PACKAGES, 'Unexpected enabled server packages');
for (const pkg of summary) {
  assert.match(pkg.hash, /^[a-f0-9]{40}$/);
  const cwd = path.join(source, packageSpec(pkg.name).sourceDirectory);
  const local = execFileSync('git', ['rev-parse', 'HEAD'], { cwd, encoding: 'utf8' }).trim();
  assert.equal(local, pkg.hash, `${pkg.name}: local revision differs from live server; supply a matching TQS_PACKAGE_SOURCE`);
  assert.equal(execFileSync('git', ['status', '--porcelain'], { cwd, encoding: 'utf8' }).trim(), '',
    `${pkg.name}: source has local changes`);
  console.log(`PASS live package revision ${pkg.name} @ ${pkg.hash}`);
}
const snapshot = path.join(repo, 'scratch/live-web-test', randomUUID());
mkdirSync(snapshot, { recursive: true });
const md5 = buildSnapshot(source, snapshot);
mkdirSync(path.dirname(config), { recursive: true, mode: 0o700 });
const account = `tqswebtest${randomBytes(5).toString('hex')}`;
const values = {
  TQS_LIVE_HOST: host, TQS_LIVE_PORT: String(port), TQS_LIVE_ROOT: snapshot,
  FK_TEST_USERNAME: account, FK_TEST_PASSWORD: randomBytes(24).toString('base64url'),
};
// Exclusive creation and private permissions; never print credential values.
writeFileSync(config, Object.entries(values).map(([k, v]) => `${k}=${JSON.stringify(v)}`).join('\n') + '\n',
  { flag: 'wx', mode: 0o600 });
console.log(`PASS local snapshot prepared; native flist MD5 ${md5}`);
console.log(`PASS private test configuration saved to ${config}`);
console.log('Account credentials prepared; run npm run test:e2e:login to register/login and verify EnterLobby.');
