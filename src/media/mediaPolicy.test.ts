import assert from 'node:assert/strict';
import {
  MAX_MEDIA_BYTES,
  buildMediaObjectKey,
  hasMediaUploadPermission,
  normalizePublicBaseUrl,
  validateMediaUploadRequest,
} from './mediaPolicy';

let passed = 0;

function pass(name: string, condition: boolean): void {
  assert.equal(condition, true, name);
  passed += 1;
  console.log(`✅ ${name}`);
}

console.log('🧪 Running media upload policy tests...');

const valid = validateMediaUploadRequest({
  filename: 'cover image.png',
  contentType: 'image/png',
  size: 1024,
  category: 'products',
});
pass('accepts an allowed image request', valid.ok);
if (valid.ok) {
  pass('derives the extension from the MIME type', valid.value.extension === '.png');
  pass(
    'builds a category and date partitioned object key',
    buildMediaObjectKey('products', valid.value.extension, new Date('2026-09-23T12:00:00Z'), 'uuid') ===
      'uploads/products/2026/09/uuid.png',
  );
}

pass(
  'rejects SVG uploads',
  !validateMediaUploadRequest({ filename: 'icon.svg', contentType: 'image/svg+xml', size: 10, category: 'banners' }).ok,
);
pass(
  'rejects files over 5 MB',
  !validateMediaUploadRequest({ filename: 'large.webp', contentType: 'image/webp', size: MAX_MEDIA_BYTES + 1, category: 'products' }).ok,
);
pass(
  'rejects path traversal in filenames',
  !validateMediaUploadRequest({ filename: '../secret.png', contentType: 'image/png', size: 10, category: 'products' }).ok,
);
pass(
  'normalizes the public base URL',
  normalizePublicBaseUrl('cdn.example.com/') === 'https://cdn.example.com',
);
pass(
  'requires manageProducts for product media',
  hasMediaUploadPermission('products', { role: 'admin', adminPermissions: { manageProducts: true } }),
);
pass(
  'requires homepage or settings permission for banner media',
  !hasMediaUploadPermission('banners', { role: 'admin', adminPermissions: { manageProducts: true } }) &&
    hasMediaUploadPermission('banners', { role: 'admin', adminPermissions: { manageSettings: true } }),
);
pass(
  'allows a super-admin claim across categories',
  hasMediaUploadPermission('banners', { role: 'customer' }, { super_admin: true }),
);

console.log(`Media upload policy tests: ${passed} passed, 0 failed`);
