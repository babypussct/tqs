import type { OrderDocument, OrderItem } from '../../order/canonical';
import { normalizeLegacyOrder } from '../../order/legacyAdapter';

export function normalizeOrder(raw: Record<string, unknown>, id: string): OrderDocument {
  return normalizeLegacyOrder({ ...raw, id });
}

export function getOrderItemUnitPrice(item: OrderItem | Record<string, unknown>): number {
  const value = (item as { unitPrice?: unknown; price?: unknown }).unitPrice
    ?? (item as { price?: unknown }).price;
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

export function getOrderItemLineTotal(item: OrderItem | Record<string, unknown>): number {
  const quantity = typeof (item as { quantity?: unknown }).quantity === 'number'
    ? Math.max(1, Math.floor((item as { quantity: number }).quantity))
    : 1;
  const lineTotal = (item as { lineTotal?: unknown }).lineTotal;
  return typeof lineTotal === 'number' && Number.isFinite(lineTotal)
    ? lineTotal
    : getOrderItemUnitPrice(item) * quantity;
}
