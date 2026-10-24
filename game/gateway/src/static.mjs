import fs from 'node:fs';
import path from 'node:path';
const types = { '.html':'text/html; charset=utf-8', '.js':'text/javascript; charset=utf-8', '.css':'text/css; charset=utf-8', '.json':'application/json; charset=utf-8',
  '.wasm':'application/wasm', '.svg':'image/svg+xml', '.png':'image/png', '.jpg':'image/jpeg', '.jpeg':'image/jpeg', '.webp':'image/webp', '.webmanifest':'application/manifest+json' };
/** Serve only the frozen public web build. Runtime and operation files are never web roots. */
export function serveStatic(root, pathname, req, res) {
  if (!root) return false;
  const relative = pathname === '/' ? 'index.html' : pathname.slice(1);
  if (!relative || relative.split('/').some(part => part.startsWith('.')) || relative.includes('\\')) return false;
  const file = path.resolve(root, relative); const type = types[path.extname(file)];
  if (!type || !file.startsWith(path.resolve(root) + path.sep) || !fs.existsSync(file)) return false;
  const canonical = fs.realpathSync(file); const canonicalRoot = fs.realpathSync(root);
  if (!canonical.startsWith(canonicalRoot + path.sep) || !fs.statSync(canonical).isFile()) return false;
  res.writeHead(200, { 'Content-Type':type, 'X-Content-Type-Options':'nosniff',
    'Cache-Control': ['version.json', 'sw.js'].includes(relative) ? 'no-store' : relative.startsWith('assets/') ? 'public, max-age=31536000, immutable' : 'no-cache' });
  if (req.method === 'HEAD') res.end();
  else { const stream=fs.createReadStream(canonical);stream.on('error',()=>res.destroy());stream.pipe(res); }
  return true;
}
