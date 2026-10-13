import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(scriptsDir, '..');

function read(relativePath: string): string {
  return fs.readFileSync(path.join(webRoot, relativePath), 'utf8');
}

function sourceFiles(dir: string, relative = ''): string[] {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const entryRelative = path.join(relative, entry.name);
    const absolute = path.join(dir, entry.name);
    if (entry.isDirectory()) return sourceFiles(absolute, entryRelative);
    return /\.(ts|tsx)$/.test(entry.name) ? [entryRelative] : [];
  });
}

test('node-forge remains pinned and production use stays encryption-only', () => {
  const packageJson = JSON.parse(read('package.json')) as {
    dependencies?: Record<string, string>;
  };
  const packageLock = JSON.parse(read('package-lock.json')) as {
    packages?: Record<string, { version?: string }>;
  };
  assert.equal(packageJson.dependencies?.['node-forge'], '1.4.0');
  assert.equal(packageLock.packages?.['node_modules/node-forge']?.version, '1.4.0');

  const forgeImportFiles = sourceFiles(path.join(webRoot, 'src'))
    .filter((relativePath) => read(path.join('src', relativePath)).includes("from 'node-forge'"))
    .sort();
  assert.deepEqual(forgeImportFiles, ['engine/connection.ts']);

  const connectionSource = read('src/engine/connection.ts');
  assert.match(connectionSource, /forge\.pki\.publicKeyFromPem/);
  assert.match(connectionSource, /key\.encrypt\(plain, 'RSAES-PKCS1-V1_5'\)/);
  assert.doesNotMatch(connectionSource, /\b(?:verify|sign|decrypt)\s*\(/,
    'the production connection must not add signature verification or private-key decryption');
});
