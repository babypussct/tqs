import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const here = path.dirname(fileURLToPath(import.meta.url));
const packageDir = path.join(here, 'tqs_qa');
const nativeCatalog = JSON.parse(fs.readFileSync(path.join(packageDir, 'catalog.json'), 'utf8'));
const browserCatalogPath = path.resolve(here, '../../../game/web/scripts/real-lua-e2e/qa-scenarios.ts');
const browserCatalog = fs.readFileSync(browserCatalogPath, 'utf8');

test('native tqs_qa catalog keeps the browser scenario ids, seeds and commands in lockstep', () => {
  for (const scenario of nativeCatalog.scenarios) {
    const key = scenario.id.includes('-') ? `'${scenario.id}'` : scenario.id;
    const match = browserCatalog.match(new RegExp(`${key.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\$&')}: \\{([\\s\\S]*?)\\n  \\},`));
    assert.ok(match, `browser QA catalog is missing ${scenario.id}`);
    const seed = match[1].match(/seed: (0x[0-9a-f]+)/u)?.[1];
    const expectedCommand = match[1].match(/expectedCommand: '([^']+)'/u)?.[1];
    assert.equal(Number(seed), scenario.seed, `${scenario.id} seed drift`);
    assert.equal(expectedCommand, scenario.expectedCommand, `${scenario.id} expected command drift`);
  }
});
