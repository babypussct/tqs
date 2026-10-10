// SPDX-License-Identifier: GPL-3.0-or-later
//
// TQS game gateway.
//
// Browsers cannot open raw TCP sockets, while freekill-asio only speaks a
// stream of CBOR arrays over TCP. This process:
//
//   1. bridges every WebSocket connection on /ws to one TCP connection to the
//      local freekill-asio server (bytes are forwarded untouched, CBOR items
//      are self-delimiting so no re-framing is needed);
//   2. serves /manifest.json (server MD5 + package list) so the web client
//      can build a valid Setup packet;
//   3. serves /bundle.zip containing every Lua/JSON file the client-side Lua
//      engine needs, built from the exact packages the server is running;
//   4. serves package media (images/audio) under /assets/.
//
// Configuration (environment variables):
//   FK_ROOT      freekill-asio working directory (contains packages/, flist.txt)
//   FK_HOST      default 127.0.0.1
//   FK_PORT      default 9527
//   PORT         HTTP/WebSocket listen port, default 8080
//   ALLOW_ORIGIN CORS origin for HTTP endpoints, default *

import http from 'node:http';
import net from 'node:net';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { WebSocketServer } from 'ws';
import { zipSync } from 'fflate';

const FK_ROOT = path.resolve(process.env.FK_ROOT ?? '/opt/freekill-hegemony/server-root');
const FK_HOST = process.env.FK_HOST ?? '127.0.0.1';
const FK_PORT = Number(process.env.FK_PORT ?? 9527);
const PORT = Number(process.env.PORT ?? 8080);
const ALLOW_ORIGIN = process.env.ALLOW_ORIGIN ?? '*';
const MAX_WS_PER_IP = Number(process.env.MAX_WS_PER_IP ?? 6);

const PACKAGES_DIR = path.join(FK_ROOT, 'packages');
const BUNDLE_EXT = new Set(['.lua', '.json']);
const MEDIA_TYPES = {
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.gif': 'image/gif',
  '.mp3': 'audio/mpeg',
  '.ogg': 'audio/ogg',
  '.wav': 'audio/wav',
};

const log = (...a) => console.log(new Date().toISOString(), ...a);

// ---------------------------------------------------------------- bundle --

function walk(dir, out = []) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    if (ent.name === '.git' || ent.name === 'node_modules') continue;
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(full, out);
    else out.push(full);
  }
  return out;
}

/** Packages that are enabled on the server (packages.db lists disabled ones). */
function listPackages() {
  return fs
    .readdirSync(PACKAGES_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory() && !d.name.startsWith('.'))
    .map((d) => d.name)
    .sort();
}

let cache = null;

function buildCache() {
  const files = {};
  const packages = listPackages();
  for (const pkg of packages) {
    for (const full of walk(path.join(PACKAGES_DIR, pkg))) {
      if (!BUNDLE_EXT.has(path.extname(full).toLowerCase())) continue;
      const rel = path.relative(FK_ROOT, full).split(path.sep).join('/');
      files[rel] = fs.readFileSync(full);
    }
  }
  const zip = Buffer.from(zipSync(files, { level: 9 }));
  const bundleHash = crypto.createHash('sha1').update(zip).digest('hex').slice(0, 16);

  // freekill-asio validates the client-supplied MD5 against md5(flist.txt).
  let md5 = '';
  const flist = path.join(FK_ROOT, 'flist.txt');
  if (fs.existsSync(flist)) {
    md5 = crypto.createHash('md5').update(fs.readFileSync(flist)).digest('hex');
  } else {
    log('WARNING: flist.txt not found; login will fail the MD5 check');
  }

  cache = {
    zip,
    manifest: {
      md5,
      packages,
      bundle: `bundle.zip?v=${bundleHash}`,
      bundleHash,
      fileCount: Object.keys(files).length,
      builtAt: new Date().toISOString(),
    },
    flistMtime: fs.existsSync(flist) ? fs.statSync(flist).mtimeMs : 0,
  };
  log(`bundle built: ${cache.manifest.fileCount} files, ${zip.length} bytes, md5=${md5}`);
  return cache;
}

function getCache() {
  const flist = path.join(FK_ROOT, 'flist.txt');
  const mtime = fs.existsSync(flist) ? fs.statSync(flist).mtimeMs : 0;
  // flist.txt is rewritten by the server whenever packages change.
  if (!cache || cache.flistMtime !== mtime) buildCache();
  return cache;
}

// ------------------------------------------------------------------ http --

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ALLOW_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
}

const server = http.createServer((req, res) => {
  cors(res);
  if (req.method === 'OPTIONS') return res.writeHead(204).end();
  if (req.method !== 'GET' && req.method !== 'HEAD') return res.writeHead(405).end();

  try {
    // A malformed percent-encoded request path is client input, not an
    // exception that should crash the entire gateway process.
    const url = new URL(req.url ?? '/', 'http://localhost');
    let p;
    try {
      p = decodeURIComponent(url.pathname);
    } catch {
      return res.writeHead(400).end();
    }
    if (p === '/healthz') {
      return res.writeHead(200, { 'Content-Type': 'text/plain' }).end('ok');
    }
    if (p === '/manifest.json') {
      const { manifest } = getCache();
      return res
        .writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-cache' })
        .end(JSON.stringify(manifest));
    }
    if (p === '/bundle.zip') {
      const { zip, manifest } = getCache();
      const requestedVersion = url.searchParams.get('v');
      // Never label a different bundle immutable under an obsolete URL.
      if (requestedVersion !== null && requestedVersion !== manifest.bundleHash) {
        return res.writeHead(404, { 'Cache-Control': 'no-store' }).end();
      }
      return res
        .writeHead(200, {
          'Content-Type': 'application/zip',
          'Content-Length': zip.length,
          'Cache-Control': requestedVersion ? 'public, max-age=31536000, immutable' : 'no-cache',
        })
        .end(zip);
    }
    if (p.startsWith('/assets/')) {
      const rel = p.slice('/assets/'.length);
      const full = path.resolve(PACKAGES_DIR, rel);
      const type = MEDIA_TYPES[path.extname(full).toLowerCase()];
      if (!full.startsWith(PACKAGES_DIR + path.sep) || !type || !fs.existsSync(full)) {
        return res.writeHead(404).end();
      }
      res.writeHead(200, {
        'Content-Type': type,
        'Cache-Control': 'public, max-age=604800',
      });
      return fs.createReadStream(full).pipe(res);
    }
  } catch (e) {
    log('http error', e);
    return res.writeHead(500).end();
  }
  res.writeHead(404).end();
});

// ------------------------------------------------------------- websocket --

const perIp = new Map();
const wss = new WebSocketServer({ server, path: '/ws', maxPayload: 1 << 20 });

wss.on('connection', (ws, req) => {
  const ip =
    (req.headers['cf-connecting-ip'] ?? req.headers['x-forwarded-for'] ?? req.socket.remoteAddress ?? '')
      .toString()
      .split(',')[0]
      .trim();
  const n = (perIp.get(ip) ?? 0) + 1;
  if (n > MAX_WS_PER_IP) {
    ws.close(1008, 'too many connections');
    return;
  }
  perIp.set(ip, n);

  const tcp = net.createConnection({ host: FK_HOST, port: FK_PORT });
  tcp.setNoDelay(true);
  const pending = [];
  let tcpReady = false;

  tcp.on('connect', () => {
    tcpReady = true;
    for (const b of pending) tcp.write(b);
    pending.length = 0;
  });
  tcp.on('data', (buf) => {
    if (ws.readyState === ws.OPEN) ws.send(buf, { binary: true });
  });
  const closeBoth = (why) => {
    if (ws.readyState === ws.OPEN || ws.readyState === ws.CONNECTING) ws.close(1000, why);
    tcp.destroy();
  };
  tcp.on('error', (e) => closeBoth(`backend error: ${e.code ?? e.message}`));
  tcp.on('close', () => closeBoth('backend closed'));

  ws.on('message', (data, isBinary) => {
    if (!isBinary) return; // protocol is binary CBOR only
    const buf = Buffer.isBuffer(data) ? data : Buffer.concat(data);
    if (tcpReady) tcp.write(buf);
    else pending.push(buf);
  });
  ws.on('close', () => {
    tcp.destroy();
    const left = (perIp.get(ip) ?? 1) - 1;
    if (left <= 0) perIp.delete(ip);
    else perIp.set(ip, left);
  });
  ws.on('error', () => tcp.destroy());
});

// Keep idle mobile connections alive through proxies (Cloudflare drops ~100s idle).
setInterval(() => {
  for (const ws of wss.clients) if (ws.readyState === ws.OPEN) ws.ping();
}, 30_000).unref();

server.listen(PORT, () => {
  log(`gateway listening on :${PORT} -> ${FK_HOST}:${FK_PORT}, root=${FK_ROOT}`);
  try {
    getCache();
  } catch (e) {
    log('initial bundle build failed:', e.message);
  }
});
