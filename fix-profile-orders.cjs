const fs = require('fs');
let content = fs.readFileSync('src/components/Profile.tsx', 'utf8');

const ordersStart = "        {/* Tab Content: ORDERS */}";
const rewardsStart = "        {/* Tab Content: REWARDS */}";

const idx1 = content.indexOf(ordersStart);
const idx2 = content.indexOf(rewardsStart);

if (idx1 !== -1 && idx2 !== -1) {
  const newOrdersTab = `        {/* Tab Content: ORDERS */}
        {activeTab === 'orders' && (
           <OrderHistory 
             orders={orders}
             getStatusConfig={getStatusConfig}
             isConfirming={isConfirming}
             handleConfirmReceived={handleConfirmReceived}
             paymentConfig={paymentConfig}
           />
        )}\n\n`;
  content = content.substring(0, idx1) + newOrdersTab + content.substring(idx2);
  fs.writeFileSync('src/components/Profile.tsx', content);
  console.log('Successfully replaced ORDERS tab');
} else {
  console.log('Could not find boundaries');
}
