import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { assertVercelContract, directoryDigest } from './output-policy.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
assertVercelContract(root);
const output = path.join(root, '.vercel/output');
const staticDir = path.join(output, 'static');
const config = JSON.parse(readFileSync(path.join(output, 'config.json'), 'utf8'));
assert.equal(config.version, 3, 'Expected Vercel Build Output API v3');
assert.ok(existsSync(path.join(staticDir, 'index.html')), 'Vercel static index is missing');
assert.deepEqual(directoryDigest(staticDir), directoryDigest(path.join(root, 'dist-shop')),
  'Vercel must package exactly dist-shop, including all hashed assets');

const endpoints = [];
function walk(directory, relative = '') {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (entry.name.startsWith('_')) continue;
    const name = path.join(relative, entry.name);
    if (entry.isDirectory()) walk(path.join(directory, entry.name), name);
    else if (entry.name.endsWith('.ts')) endpoints.push(name.replace(/\.ts$/, ''));
  }
}
walk(path.join(root, 'api'));
for (const endpoint of endpoints) {
  assert.ok(existsSync(path.join(output, 'functions/api', `${endpoint}.func/.vc-config.json`)),
    `Vercel API function missing: /api/${endpoint}`);
}
console.log(`PASS Vercel local artifact: ${directoryDigest(staticDir).files} static files byte-match dist-shop; ${endpoints.length} API functions present`);
