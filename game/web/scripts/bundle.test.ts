import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { test } from 'node:test';
import { zipSync } from 'fflate';
import { loadGatewayBundle } from '../src/engine/bundle';

const encoder = new TextEncoder();
const defaultFiles = {
  'packages/freekill-core/init.lua': encoder.encode('-- core'),
  'packages/utility/init.lua': encoder.encode('-- utility'),
  'packages/hegemony/init.lua': encoder.encode('-- hegemony'),
  'packages/hegemony/description.md': encoder.encode('loaded by dofile'),
};

function fixture(files: Record<string, Uint8Array> = defaultFiles) {
  const zip = zipSync(files, { level: 0 });
  const bundleHash = createHash('sha1').update(zip).digest('hex').slice(0, 16);
  const manifest = {
    md5: 'a'.repeat(32), packages: ['freekill-core', 'utility', 'hegemony'],
    fileCount: Object.keys(files).length,
    bundle: `bundle.zip?v=${bundleHash}`, bundleHash,
  };
  return { zip, manifest };
}

async function withFixture<T>(data: ReturnType<typeof fixture>, run: () => Promise<T>): Promise<T> {
  const previousFetch = globalThis.fetch;
  globalThis.fetch = async (input) => {
    const url = String(input);
    if (url.endsWith('/manifest.json')) return Response.json(data.manifest);
    if (url.includes('/bundle.zip?v=')) return new Response(data.zip.slice(), {
      headers: { 'content-length': String(data.zip.length) },
    });
    return new Response(null, { status: 404 });
  };
  try {
    return await run();
  } finally {
    globalThis.fetch = previousFetch;
  }
}

test('bundle loader verifies manifest, checksum, paths and entrypoints', async () => {
  await withFixture(fixture(), async () => {
    const loaded = await loadGatewayBundle('/gateway');
    assert.equal(loaded.files.size, 4);
    assert.deepEqual(loaded.files.get('packages/hegemony/init.lua'), defaultFiles['packages/hegemony/init.lua']);
  });
});

test('mismatched checksum prevents mounting a bundle', async () => {
  const data = fixture();
  data.manifest.bundleHash = '0'.repeat(16);
  data.manifest.bundle = `bundle.zip?v=${data.manifest.bundleHash}`;
  await withFixture(data, async () => {
    await assert.rejects(loadGatewayBundle('/gateway'), /checksum/);
  });
});

test('ZIP traversal and undeclared packages are rejected', async () => {
  for (const name of ['packages/hegemony/../escape.lua', 'packages/unknown/init.lua']) {
    await withFixture(fixture({ ...defaultFiles, [name]: encoder.encode('x') }), async () => {
      await assert.rejects(loadGatewayBundle('/gateway'), /không an toàn|không có trong manifest/);
    });
  }
});

test('incomplete bundles and manifest counts cannot boot Lua', async () => {
  await withFixture(fixture({ 'packages/hegemony/init.lua': encoder.encode('ok') }), async () => {
    await assert.rejects(loadGatewayBundle('/gateway'), /Thiếu Lua entrypoint/);
  });
  const data = fixture();
  data.manifest.fileCount += 1;
  await withFixture(data, async () => {
    await assert.rejects(loadGatewayBundle('/gateway'), /Số tệp package không khớp/);
  });
});
