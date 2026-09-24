import type { OrderItemInput } from './orderService';

export const DEFAULT_SLEEVES_PRICE = 20_000;
export const DEFAULT_BOX_UPGRADE_PRICE = 50_000;
export const DEFAULT_QUICK_ADD_SLEEVES_NAME = 'Mua kèm 200 Bọc bài (Sleeves)';
export const DEFAULT_QUICK_ADD_SLEEVES_PRICE = 50_000;

export interface ProductPricingRecord {
  price?: unknown;
  customVariants?: Array<{
    name: string;
    options: Array<string | { name: string; priceAdjustment?: number }>;
  }>;
  quickAddAccessories?: Array<{ name: string; price: number }>;
  quickAddAccessory?: { name: string; price: number };
}

/**
 * One authoritative price resolver for create-order and quote flows.
 * Client CartItem.price is intentionally not accepted here.
 */
export function resolveProductUnitPrice(
  product: ProductPricingRecord,
  item: Pick<OrderItemInput, 'selectedBox' | 'selectedVariants' | 'addSleeves' | 'quickAddAccessoryNames'>,
): number {
  let unitPrice = Math.max(0, Number(product.price) || 0);

  if (item.selectedBox?.includes('Hộp Sắt')) {
    unitPrice += DEFAULT_BOX_UPGRADE_PRICE;
  }

  for (const [variantName, optionName] of Object.entries(item.selectedVariants || {})) {
    const variant = product.customVariants?.find((candidate) => candidate.name === variantName);
    if (!variant) continue;
    const option = variant.options.find((candidate) =>
      (typeof candidate === 'string' ? candidate : candidate.name) === optionName,
    );
    if (!option) {
      throw new Error(`INVALID_PRODUCT_VARIANT:${variantName}:${optionName}`);
    }
    if (typeof option !== 'string') {
      unitPrice += Number(option.priceAdjustment) || 0;
    }
  }

  if (item.addSleeves) unitPrice += DEFAULT_SLEEVES_PRICE;

  const catalog = product.quickAddAccessories?.length
    ? product.quickAddAccessories
    : product.quickAddAccessory
      ? [product.quickAddAccessory]
      : [];
  for (const name of Array.from(new Set(item.quickAddAccessoryNames || []))) {
    const accessory = catalog.find((candidate) => candidate.name === name);
    if (accessory) {
      unitPrice += Math.max(0, Number(accessory.price) || 0);
    } else if (name === DEFAULT_QUICK_ADD_SLEEVES_NAME) {
      unitPrice += DEFAULT_QUICK_ADD_SLEEVES_PRICE;
    } else {
      throw new Error(`INVALID_QUICK_ADD_ACCESSORY:${name}`);
    }
  }

  return Math.round(unitPrice);
}
