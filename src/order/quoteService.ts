import type { OrderItem } from './canonical.js';
import { calculateOrderTotals, normalizeRewardsConfig, type CalculateOrderTotalsInput } from './money.js';
import { resolveProductUnitPrice } from './pricing.js';
import { toDate } from '../shared/data/date.js';
import type {
  AuthenticatedActor,
  CreateOrderInput,
  OrderServiceDependencies,
} from './orderService.js';
import { assertValidOrderInput } from './orderService.js';

export interface OrderQuote {
  items: OrderItem[];
  totalAmount: number;
  shippingFee: number;
  voucherDiscountAmount: number;
  pointsDiscountAmount: number;
  discountAmount: number;
  finalAmount: number;
  rewardEligibleAmount: number;
  discountCode: string | null;
  pointsApplied: number;
  voucher: Record<string, unknown> | null;
}

export type QuoteOrderInput = Omit<CreateOrderInput, 'idempotencyKey'> & {
  idempotencyKey?: string;
};

function assertValidQuoteInput(input: QuoteOrderInput): void {
  assertValidOrderInput(input, { requireShippingInfo: false });
}

/** Read-only counterpart of createOrder. It deliberately shares the same
 * pricing and money functions so checkout can preview the server result. */
export async function quoteOrder(
  actor: AuthenticatedActor,
  input: QuoteOrderInput,
  deps: OrderServiceDependencies,
): Promise<OrderQuote> {
  assertValidQuoteInput(input);
  const userProfile = await deps.getUserProfile(actor.uid);
  if (userProfile?.isBanned) throw new Error('ACCOUNT_BANNED');

  const paymentConfig = deps.getPaymentConfig ? await deps.getPaymentConfig() : null;
  if (input.paymentMethod === 'vietqr' && paymentConfig?.isActive === false) {
    throw new Error('PAYMENT_METHOD_DISABLED');
  }
  const rewardsConfig = normalizeRewardsConfig(
    deps.getRewardsConfig ? await deps.getRewardsConfig() : null,
  );
  if (input.pointsToUse && !rewardsConfig.isActive) throw new Error('POINTS_DISABLED');
  if (input.pointsToUse && input.pointsToUse < rewardsConfig.minPointsToUse) {
    throw new Error('MIN_POINTS_REQUIRED');
  }

  const resolvedItems: OrderItem[] = [];
  const categories = new Map<string, string>();
  const stockRequested = new Map<string, number>();

  for (const itemInput of input.items) {
    const product = await deps.getProduct(itemInput.productId);
    if (!product) throw new Error('PRODUCT_NOT_FOUND');
    if (product.isActive === false) throw new Error('PRODUCT_INACTIVE');
    const tierRank: Record<string, number> = { bronze: 0, silver: 1, gold: 2, diamond: 3 };
    const requiredTier = typeof product.minTierRequired === 'string' ? product.minTierRequired.toLowerCase() : '';
    const currentTier = String(userProfile?.tier || 'bronze').toLowerCase();
    if (requiredTier && tierRank[requiredTier] !== undefined && (tierRank[currentTier] ?? 0) < tierRank[requiredTier]) {
      throw new Error('TIER_REQUIRED');
    }
    if (Array.isArray(product.allowedPaymentMethods) && !product.allowedPaymentMethods.includes(input.paymentMethod)) {
      throw new Error('PRODUCT_PAYMENT_METHOD_NOT_ALLOWED');
    }

    const quantity = Math.max(1, Math.floor(itemInput.quantity));
    const currentStock = typeof product.stock === 'number' ? product.stock : 0;
    const nextRequested = (stockRequested.get(product.id) || 0) + quantity;
    if (currentStock < nextRequested) throw new Error('INSUFFICIENT_STOCK');
    stockRequested.set(product.id, nextRequested);
    categories.set(product.id, String(product.type || ''));

    const unitPrice = resolveProductUnitPrice(product, itemInput);
    resolvedItems.push({
      productId: product.id,
      name: String(product.name || ''),
      unitPrice,
      quantity,
      lineTotal: unitPrice * quantity,
      selectedBox: itemInput.selectedBox || null,
      selectedLang: itemInput.selectedLang || null,
      selectedVariants: itemInput.selectedVariants || null,
      addSleeves: Boolean(itemInput.addSleeves),
      quickAddAccessoryNames: itemInput.quickAddAccessoryNames || null,
      image: String(product.image || ''),
    });
  }

  const shippingConfig = deps.getShippingConfig ? await deps.getShippingConfig() : null;
  const configuredShippingFee = Number(shippingConfig?.defaultFee);
  const defaultShippingFee = Number.isFinite(configuredShippingFee) && configuredShippingFee >= 0
    ? Math.min(configuredShippingFee, Number.MAX_SAFE_INTEGER)
    : 30000;
  const freeshipThreshold = shippingConfig?.freeshipThreshold !== undefined
    ? shippingConfig.freeshipThreshold === null
      ? null
      : Number.isFinite(Number(shippingConfig.freeshipThreshold)) && Number(shippingConfig.freeshipThreshold) >= 0
      ? Math.min(Number(shippingConfig.freeshipThreshold), Number.MAX_SAFE_INTEGER)
      : 500000
    : 500000;

  let voucher: NonNullable<CalculateOrderTotalsInput['voucher']> | null = null;
  if (input.discountCode) {
    const cleanCode = input.discountCode.trim().toUpperCase();
    const candidate = await deps.getVoucher(cleanCode);
    if (!candidate || candidate.isActive === false) throw new Error('INVALID_DISCOUNT_CODE');

    const now = Date.now();
    const startsAt = toDate(candidate.startDate)?.getTime() ?? 0;
    const endsAt = toDate(candidate.endDate)?.getTime() ?? Number.MAX_SAFE_INTEGER;
    if (now < startsAt) throw new Error('DISCOUNT_NOT_STARTED');
    if (now > endsAt) throw new Error('DISCOUNT_EXPIRED');
    if (candidate.usageLimit && Number(candidate.usedCount || 0) >= Number(candidate.usageLimit)) {
      throw new Error('DISCOUNT_USAGE_EXHAUSTED');
    }
    if (candidate.customerType && deps.getUserOrderCount) {
      const orderCount = await deps.getUserOrderCount(actor.uid);
      if (candidate.customerType === 'new' && orderCount > 0) throw new Error('DISCOUNT_CUSTOMER_TYPE_INVALID');
      if (candidate.customerType === 'returning' && orderCount === 0) throw new Error('DISCOUNT_CUSTOMER_TYPE_INVALID');
    }
    if (candidate.usageLimitPerUser && deps.getUserOrderCount) {
      const usageCount = await deps.getUserOrderCount(actor.uid, candidate.code);
      if (usageCount >= Number(candidate.usageLimitPerUser)) throw new Error('DISCOUNT_USAGE_PER_USER_EXHAUSTED');
    }
    if (candidate.applicableTiers?.length && !candidate.applicableTiers.includes(userProfile?.tier || 'bronze')) {
      throw new Error('DISCOUNT_TIER_NOT_ELIGIBLE');
    }

    const hasScope = Boolean(candidate.applicableProducts?.length || candidate.applicableCategories?.length);
    const eligibleItems = resolvedItems.filter((item) => {
      const category = categories.get(item.productId) || '';
      if (candidate.excludeCategories?.includes(category)) return false;
      if (!hasScope) return true;
      return Boolean(
        candidate.applicableProducts?.includes(item.productId) ||
        candidate.applicableCategories?.includes(category),
      );
    });
    const eligibleTotal = eligibleItems.reduce((sum, item) => sum + item.lineTotal, 0);
    if (hasScope && eligibleItems.length === 0) throw new Error('DISCOUNT_SCOPE_INVALID');
    if (candidate.minOrderValue && eligibleTotal < Number(candidate.minOrderValue)) {
      throw new Error('DISCOUNT_MIN_ORDER_NOT_MET');
    }

    voucher = candidate as NonNullable<CalculateOrderTotalsInput['voucher']>;
  }

  const pointsToUse = Math.max(0, Math.floor(input.pointsToUse || 0));
  const moneyInput: CalculateOrderTotalsInput = {
    items: resolvedItems.map((item) => ({
      ...item,
      category: categories.get(item.productId),
    })),
    defaultShippingFee,
    shippingActive: shippingConfig?.isActive !== false,
    hasFreeshipProduct: Array.isArray(shippingConfig?.freeshipProductIds) &&
      resolvedItems.some((item) => shippingConfig.freeshipProductIds.includes(item.productId)),
    freeshipThreshold,
    voucher,
    pointsToUse: rewardsConfig.isActive ? pointsToUse : 0,
    userPointsBalance: typeof userProfile?.points === 'number' ? userProfile.points : 0,
    pointsRate: rewardsConfig.pointValueVND,
    maxPointsDiscountPercent: rewardsConfig.maxDiscountPercentage,
  };
  const money = calculateOrderTotals(moneyInput);

  return {
    items: resolvedItems,
    ...money,
    discountCode: voucher?.code || null,
    pointsApplied: Math.floor(money.pointsDiscountAmount / rewardsConfig.pointValueVND),
    voucher: voucher as Record<string, unknown> | null,
  };
}
