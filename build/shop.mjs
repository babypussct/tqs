import assert from 'node:assert/strict';
import { rmSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { build, resolveConfig } from 'vite';
import { SHOP_OUTPUT, assertShopOutput, assertVercelContract, protectedOutputs, assertProtectedOutputs } from './output-policy.mjs';

const root = fileURLToPath(new URL('../', import.meta.url)).replace(/\/$/, '');
const action = process.argv[2];
assert.ok(['build', 'clean', 'check'].includes(action) && process.argv.length === 3,
  'Usage: node build/shop.mjs build|clean|check (output overrides are forbidden)');
assertVercelContract(root);
const destination = assertShopOutput(root, SHOP_OUTPUT);
const before = protectedOutputs(root);
try {
  if (action === 'clean') rmSync(destination, { recursive: true, force: true });
  else if (action === 'build') await build({ root });
  else {
    const config = await resolveConfig({ root }, 'build');
    assertShopOutput(root, config.build.outDir);
  }
} finally {
  assertProtectedOutputs(root, before);
}
console.log(`PASS shop ${action}: dist-shop isolated; protected outputs ${JSON.stringify(before)}`);
