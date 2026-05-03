const fs = require('fs');

let content = fs.readFileSync('src/components/Profile.tsx', 'utf8');

// 1. Add Imports
content = content.replace(
  "import VoucherCenter from './VoucherCenter';",
  "import VoucherCenter from './VoucherCenter';\nimport OrderHistory from './profile/OrderHistory';\nimport UserSettings from './profile/UserSettings';"
);

// 2. Remove states and filteredOrders logic
content = content.replace(
  "  const [expandedPaymentOrderId, setExpandedPaymentOrderId] = useState<string | null>(null);\n  const [activeTab, setActiveTab] = useState<'overview' | 'orders' | 'rewards' | 'vouchers' | 'settings'>('overview');\n  const [orderFilter, setOrderFilter] = useState<'all' | 'pending' | 'shipping' | 'delivered'>('all');",
  "  const [activeTab, setActiveTab] = useState<'overview' | 'orders' | 'rewards' | 'vouchers' | 'settings'>('overview');"
);

const filteredOrdersStart = "  const filteredOrders = useMemo(() => {";
const filteredOrdersEnd = "  }, [orders, orderFilter]);\n";
const idx1 = content.indexOf(filteredOrdersStart);
const idx2 = content.indexOf(filteredOrdersEnd) + filteredOrdersEnd.length;
if (idx1 !== -1 && idx2 !== -1) {
  content = content.substring(0, idx1) + content.substring(idx2);
}

// 3. Replace ORDERS tab
const ordersTabStart = "        {/* Tab Content: ORDERS */}\n        {activeTab === 'orders' && (\n          <div className=\"space-y-6 animate-fade-in transition-all\">";
const ordersTabEnd = "              )}\n           </div>\n        )}";

const ordersReplacement = `        {/* Tab Content: ORDERS */}
        {activeTab === 'orders' && (
           <OrderHistory 
             orders={orders}
             getStatusConfig={getStatusConfig}
             isConfirming={isConfirming}
             handleConfirmReceived={handleConfirmReceived}
             paymentConfig={paymentConfig}
           />
        )}`;

// wait, let's find the exact end of ORDERS tab.
// In the view_file, it ended at line 650: "        )}\n\n        {/* Tab Content: REWARDS */}"
const ordersRegex = /\s*\{\/\* Tab Content: ORDERS \*\/\}\s*\{activeTab === 'orders' && \([\s\S]*?\}\)\}\s*<\/div>\s*\)\}\s*(?=\{\/\* Tab Content: REWARDS \*\/)/;
content = content.replace(ordersRegex, `\n        {/* Tab Content: ORDERS */}
        {activeTab === 'orders' && (
           <OrderHistory 
             orders={orders}
             getStatusConfig={getStatusConfig}
             isConfirming={isConfirming}
             handleConfirmReceived={handleConfirmReceived}
             paymentConfig={paymentConfig}
           />
        )}\n\n        `);

// 4. Replace SETTINGS tab
const settingsRegex = /\s*\{\/\* Tab Content: SETTINGS \*\/\}\s*\{activeTab === 'settings' && \([\s\S]*?<\/div>\s*\)\}\s*(?=<\/div>\s*<\/div>\s*\);)/;
content = content.replace(settingsRegex, `\n        {/* Tab Content: SETTINGS */}
        {activeTab === 'settings' && (
           <UserSettings user={user} logout={logout} />
        )}\n\n      `);

fs.writeFileSync('src/components/Profile.tsx', content);
console.log('Successfully updated Profile.tsx');
