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
//   3. serves /bundle.zip containing every Lua/JSON/Markdown file the
//      client-side Lua engine needs, built from the exact packages the server
//      is running (some upstream game-mode descriptions are loaded with
//      dofile at startup);
//   4. serves package media (images/audio) under /assets/.
//
// Configuration (environment variables):
//   FK_ROOT      freekill-asio working directory (contains packages/, flist.txt)
//   FK_HOST      default 127.0.0.1
//   FK_PORT      default 9527
//   PORT         HTTP/WebSocket listen port, default 8080
//   ALLOW_ORIGIN CORS origin for HTTP endpoints, default *

import { serveStatic } from './static.mjs';
import http from 'node:http';
import net from 'node:net';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { WebSocketServer } from 'ws';
import { zipSync } from 'fflate';
import { positiveInteger, normalizedIp, clientIp, originAllowed, consume } from './security.mjs';

const WEB_DIST = process.env.WEB_DIST ? path.resolve(process.env.WEB_DIST) : null;
const FK_ROOT = path.resolve(process.env.FK_ROOT ?? '/opt/freekill-hegemony/server-root');
const FK_HOST = process.env.FK_HOST ?? '127.0.0.1';
const FK_PORT = positiveInteger('FK_PORT', 9527, 65535);
const PORT = positiveInteger('PORT', 8080, 65535);
const BIND_HOST = process.env.BIND_HOST ?? '127.0.0.1';
const ALLOW_ORIGIN = process.env.ALLOW_ORIGIN ?? '*';
const MAX_WS_PER_IP = positiveInteger('MAX_WS_PER_IP', 6, 1024);
const MAX_CONNECTIONS = positiveInteger('MAX_CONNECTIONS', 128, 10000);
const MAX_QUEUE_BYTES = positiveInteger('MAX_QUEUE_BYTES', 1 << 20, 16 << 20);
const CONNECT_TIMEOUT_MS = positiveInteger('CONNECT_TIMEOUT_MS', 10000, 60000);
const allowedOrigins = new Set(ALLOW_ORIGIN.split(',').map(x => x.trim()));
const trustedProxies = new Set((process.env.TRUSTED_PROXIES ?? '').split(',').filter(Boolean).map(normalizedIp));

const PACKAGES_DIR = path.join(FK_ROOT, 'packages');
// QA orchestration is native-server-only. Even when a QA runtime is mounted
// beside this gateway, its package source and media must never be sent to a
// browser bundle or exposed through /assets/.
const SERVER_ONLY_PACKAGES = new Set(['tqs_qa']);
const BUNDLE_EXT = new Set(['.lua', '.json', '.md']);
// fflate serializes ZIP dates with local Date getters. Construct the frozen
// calendar value in local time so its DOS timestamp is identical in UTC and
// non-UTC deployments.
const ZIP_MTIME = new Date(2000, 0, 1, 0, 0, 0);
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
const compareEntryNames = (a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0);

const log = (...a) => console.log(new Date().toISOString(), ...a);

// ---------------------------------------------------------------- bundle --

function walk(dir, out = []) {
  // Keep bundle member order stable across cold starts so the cache-busting
  // hash is reproducible for one pinned runtime.
  for (const ent of fs.readdirSync(dir, { withFileTypes: true }).sort(compareEntryNames)) {
    if (ent.name === '.git' || ent.name === 'node_modules') continue;
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(full, out);
    else if (ent.isFile()) out.push(full);
  }
  return out;
}

/** Packages that are enabled on the server (packages.db lists disabled ones). */
function listPackages() {
  return fs
    .readdirSync(PACKAGES_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory() && !d.name.startsWith('.') && !SERVER_ONLY_PACKAGES.has(d.name))
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
  // fflate defaults ZIP entry timestamps to the current time. Pin the
  // timestamp so identical runtime bytes produce the same cache-busting hash
  // after every cold start.
  const zip = Buffer.from(zipSync(files, { level: 9, mtime: ZIP_MTIME }));
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

function cors(req, res) {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  if (allowedOrigins.has('*')) res.setHeader('Access-Control-Allow-Origin', '*');
  else if (originAllowed(req.headers.origin, allowedOrigins)) {
    res.setHeader('Access-Control-Allow-Origin', req.headers.origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
}

const server = http.createServer((req, res) => {
  if (WEB_DIST && req.url?.startsWith('/gateway/')) req.url = req.url.slice('/gateway'.length);
  cors(req, res);
  if (req.headers.origin && !originAllowed(req.headers.origin, allowedOrigins)) return res.writeHead(403).end();
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
    if (serveStatic(WEB_DIST, p, req, res)) return;
    if (p.startsWith('/assets/')) {
      const rel = p.slice('/assets/'.length);
      const packageName = rel.split('/')[0];
      if (SERVER_ONLY_PACKAGES.has(packageName)) return res.writeHead(404).end();
      const full = path.resolve(PACKAGES_DIR, rel);
      const type = MEDIA_TYPES[path.extname(full).toLowerCase()];
      if (!full.startsWith(PACKAGES_DIR + path.sep) || !type || !fs.existsSync(full)) {
        return res.writeHead(404).end();
      }
      const realRoot = fs.realpathSync(PACKAGES_DIR);
      const realFile = fs.realpathSync(full);
      if (!realFile.startsWith(realRoot + path.sep) || !fs.statSync(realFile).isFile()) return res.writeHead(404).end();
      res.writeHead(200, {
        'Content-Type': type,
        'Cache-Control': 'public, max-age=604800',
      });
      const stream = fs.createReadStream(realFile);
      stream.on('error', () => res.destroy());
      return stream.pipe(res);
    }
  } catch (e) {
    log('http error', e);
    return res.writeHead(500).end();
  }
  res.writeHead(404).end();
});

// ------------------------------------------------------------- websocket --

const perIp = new Map();
const wss = new WebSocketServer({ noServer: true, maxPayload: 1 << 20, perMessageDeflate: false });
server.on('upgrade', (req, socket, head) => {
  if (WEB_DIST && req.url === '/gateway/ws') req.url = '/ws';
  if (req.url !== '/ws' || !originAllowed(req.headers.origin, allowedOrigins)) {
    socket.end('HTTP/1.1 403 Forbidden\r\nConnection: close\r\nContent-Length: 0\r\n\r\n'); return;
  }
  if (wss.clients.size >= MAX_CONNECTIONS) {
    socket.end('HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\nContent-Length: 0\r\n\r\n'); return;
  }
  wss.handleUpgrade(req, socket, head, ws => wss.emit('connection', ws, req));
});

wss.on('connection', (ws, req) => {
  const ip = clientIp(req, trustedProxies);
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
  let pendingBytes = 0;
  let alive = true;
  const bucket = { messages: 120, messageCapacity: 120, messageRate: 12,
    bytes: MAX_QUEUE_BYTES, byteCapacity: MAX_QUEUE_BYTES, byteRate: 128 * 1024, updated: Date.now() };
  const connectTimer = setTimeout(() => closeBoth('backend connection timeout'), CONNECT_TIMEOUT_MS);
  connectTimer.unref();
  ws.on('pong', () => { alive = true; });
  ws.isAlive = () => { const wasAlive = alive; alive = false; return wasAlive; };

  tcp.on('connect', () => {
    clearTimeout(connectTimer);
    tcpReady = true;
    for (const b of pending) tcp.write(b);
    pending.length = 0; pendingBytes = 0;
  });
  tcp.on('data', (buf) => {
    if (ws.readyState !== ws.OPEN) return;
    if (ws.bufferedAmount + buf.length > MAX_QUEUE_BYTES) return closeBoth('client too slow');
    tcp.pause();
    ws.send(buf, { binary: true }, error => {
      if (error) closeBoth('client transport error'); else if (!tcp.destroyed) tcp.resume();
    });
  });
  const closeBoth = (why) => {
    clearTimeout(connectTimer);
    pending.length = 0; pendingBytes = 0;
    if (ws.readyState === ws.OPEN || ws.readyState === ws.CONNECTING) ws.close(1000, why);
    tcp.destroy();
  };
  tcp.on('error', (e) => closeBoth(`backend error: ${e.code ?? e.message}`));
  tcp.on('close', () => closeBoth('backend closed'));
  tcp.on('drain', () => ws.resume());

  ws.on('message', (data, isBinary) => {
    if (!isBinary) return closeBoth('binary protocol required');
    const buf = Buffer.isBuffer(data) ? data : Buffer.concat(data);
    if (!consume(bucket, buf.length) || pendingBytes + tcp.writableLength + buf.length > MAX_QUEUE_BYTES)
      return closeBoth('traffic limit exceeded');
    if (tcpReady) { if (!tcp.write(buf)) ws.pause(); }
    else { pending.push(buf); pendingBytes += buf.length; }
  });
  ws.on('close', () => {
    clearTimeout(connectTimer);
    pending.length = 0; pendingBytes = 0;
    tcp.destroy();
    const left = (perIp.get(ip) ?? 1) - 1;
    if (left <= 0) perIp.delete(ip);
    else perIp.set(ip, left);
  });
  ws.on('error', () => tcp.destroy());
});

// Keep idle mobile connections alive through proxies (Cloudflare drops ~100s idle).
setInterval(() => {
  for (const ws of wss.clients) if (ws.readyState === ws.OPEN) {
    if (!ws.isAlive?.()) ws.terminate(); else ws.ping();
  }
}, 30_000).unref();

server.listen(PORT, BIND_HOST, () => {
  log(`gateway listening on :${PORT} -> ${FK_HOST}:${FK_PORT}, root=${FK_ROOT}`);
  try {
    getCache();
  } catch (e) {
    log('initial bundle build failed:', e.message);
  }
});
