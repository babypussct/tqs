const fs = require('fs');

let content = fs.readFileSync('src/components/Checkout.tsx', 'utf8');

// 1. Replace imports and props
content = content.replace(
  /import \{ cloudinaryUrl \} from '\.\.\/utils\/cloudinaryUrl';\s+interface CheckoutProps \{[\s\S]*?export default function Checkout\(\{.*\}\: CheckoutProps\) \{/m,
  `import { cloudinaryUrl } from '../utils/cloudinaryUrl';
import { useCart } from '../contexts/CartContext';
import VietQRModal from './checkout/VietQRModal';
import OrderSummary from './checkout/OrderSummary';

export default function Checkout() {
  const { cartItems, clearCart, updateQuantity: onUpdateQuantity, removeItem: onRemoveItem } = useCart();`
);

// 2. Replace VietQRModal
const vietQrStart = `    if (paymentMethod === 'vietqr') {
      return (
        <div className="max-w-3xl mx-auto px-4 py-16 sm:px-6 sm:py-24 lg:px-8 text-center">`;

const vietQrEnd = `              </button>
            </div>
          </div>
        </div>
      );
    }

    return (
      <div className="max-w-3xl mx-auto px-4 py-16 sm:px-6 sm:py-24 lg:px-8 text-center">`;

const vietQrReplacement = `    if (paymentMethod === 'vietqr') {
      return (
        <VietQRModal
          paymentConfig={paymentConfig}
          orderFinalAmount={orderFinalAmount}
          orderTotalAmount={orderTotalAmount}
          createdOrderId={createdOrderId}
          onConfirm={() => navigate('/profile')}
          onLater={() => navigate('/profile')}
        />
      );
    }

    return (
      <div className="max-w-3xl mx-auto px-4 py-16 sm:px-6 sm:py-24 lg:px-8 text-center">`;

const idxStart1 = content.indexOf(vietQrStart);
const idxEnd1 = content.indexOf(vietQrEnd) + vietQrEnd.length;
if (idxStart1 !== -1 && idxEnd1 !== -1) {
  content = content.substring(0, idxStart1) + vietQrReplacement + content.substring(idxEnd1 - 85); // 85 is length of "    return (\n      <div className=\"max-w-3xl mx-auto px-4 py-16 sm:px-6 sm:py-24 lg:px-8 text-center\">"
}

// 3. Replace Order Summary
const summaryStart = `        {/* Order Summary */}
        <div className="lg:col-span-5">
          <div className="bg-white dark:bg-zinc-900 rounded-2xl p-6 sm:p-8 border border-gray-200 dark:border-zinc-800 shadow-sm sticky top-24">`;

const summaryEnd = `                'Đặt Hàng'
              )}
            </button>
          </div>
        </div>
      </div>

      {showVoucherModal && (`;

const summaryReplacement = `        {/* Order Summary */}
        <div className="lg:col-span-5">
          <OrderSummary
            cartItems={cartItems}
            onUpdateQuantity={onUpdateQuantity}
            onRemoveItem={onRemoveItem}
            totalAmount={totalAmount}
            shippingFee={shippingFee}
            discountAmount={discountAmount}
            pointsDiscountAmount={pointsDiscountAmount}
            finalAmount={finalAmount}
            shippingConfig={shippingConfig}
            threshold={threshold}
            rewardsConfig={rewardsConfig}
            userProfile={userProfile}
            appliedPoints={appliedPoints}
            pointsToUseInput={pointsToUseInput}
            setPointsToUseInput={setPointsToUseInput}
            setAppliedPoints={setAppliedPoints}
            appliedDiscount={appliedDiscount}
            discountCodeInput={discountCodeInput}
            setDiscountCodeInput={setDiscountCodeInput}
            handleApplyDiscount={handleApplyDiscount}
            removeDiscount={removeDiscount}
            isApplyingDiscount={isApplyingDiscount}
            setShowVoucherModal={setShowVoucherModal}
            isSubmitting={isSubmitting}
          />
        </div>
      </div>

      {showVoucherModal && (`;

const idxStart2 = content.indexOf(summaryStart);
const idxEnd2 = content.indexOf(summaryEnd) + summaryEnd.length;

if (idxStart2 !== -1 && idxEnd2 !== -1) {
  content = content.substring(0, idxStart2) + summaryReplacement + content.substring(idxEnd2 - 27); // 27 is length of "      {showVoucherModal && ("
}

fs.writeFileSync('src/components/Checkout.tsx', content);
console.log('Successfully updated Checkout.tsx');
