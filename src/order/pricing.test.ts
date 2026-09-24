import assert from 'node:assert/strict';
import { DEFAULT_BOX_UPGRADE_PRICE, DEFAULT_SLEEVES_PRICE, resolveProductUnitPrice } from './pricing';

const product = {
  price: 200_000,
  customVariants: [
    {
      name: 'Phiên bản',
      options: ['Tiêu chuẩn', { name: 'Cao cấp', priceAdjustment: 30_000 }],
    },
  ],
  quickAddAccessories: [{ name: 'Túi bảo vệ', price: 15_000 }],
};

const resolved = resolveProductUnitPrice(product, {
  selectedBox: 'Hộp Sắt',
  selectedVariants: { 'Phiên bản': 'Cao cấp' },
  addSleeves: true,
  quickAddAccessoryNames: ['Túi bảo vệ'],
});

assert.equal(
  resolved,
  200_000 + DEFAULT_BOX_UPGRADE_PRICE + 30_000 + DEFAULT_SLEEVES_PRICE + 15_000,
  'all server-side price components should be applied exactly once',
);

assert.equal(
  resolveProductUnitPrice(product, {
    selectedVariants: { 'Phiên bản': 'Tiêu chuẩn' },
    quickAddAccessoryNames: [],
  }),
  200_000,
  'a standard configuration should retain the catalog price',
);

assert.throws(
  () => resolveProductUnitPrice(product, { selectedVariants: { 'Phiên bản': 'Không tồn tại' } }),
  /INVALID_PRODUCT_VARIANT/,
  'unknown variant options must be rejected by the authoritative resolver',
);

assert.throws(
  () => resolveProductUnitPrice(product, { quickAddAccessoryNames: ['Không tồn tại'] }),
  /INVALID_QUICK_ADD_ACCESSORY/,
  'unknown accessories must be rejected by the authoritative resolver',
);

console.log('pricing tests: 4 passed, 0 failed');
