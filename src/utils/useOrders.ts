import { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, doc, updateDoc, serverTimestamp, increment, getDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { Order, RewardsConfig } from '../types';
import { handleFirestoreError, OperationType } from './firebaseError';
import { toast } from 'sonner';
import { DEFAULT_REWARDS_CONFIG } from './useRewardsConfig';

export function useOrders() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, 'orders'), orderBy('createdAt', 'desc'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const ordersData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Order[];
      
      setOrders(ordersData);
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.LIST, 'orders');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const updateOrderStatus = async (orderId: string, newStatus: Order['status'], userId?: string, amount?: number) => {
    try {
      await updateDoc(doc(db, 'orders', orderId), {
        status: newStatus,
        updatedAt: serverTimestamp()
      });

      // Update Points & Tier if delivered
      if (newStatus === 'delivered' && userId && amount) {
        try {
          const userRef = doc(db, 'users', userId);
          const userSnap = await getDoc(userRef);
          
          if (userSnap.exists()) {
            const userData = userSnap.data();
            const currentSpent = userData.totalSpent || 0;
            const currentOrders = userData.totalOrders || 0;
            const newSpent = currentSpent + amount;
            const newOrders = currentOrders + 1;

            // Fetch Rewards Config
            const configRef = doc(db, 'system_settings', 'tiers_config');
            const configSnap = await getDoc(configRef);
            const config: RewardsConfig = configSnap.exists() ? (configSnap.data() as RewardsConfig) : DEFAULT_REWARDS_CONFIG;
            
            let pointsEarned = 0;
            let newTier = userData.tier || 'bronze';

            if (config && config.isActive) {
              const currentTierKey = userData.tier || 'bronze';
              const currentTierConfig = config.tiers[currentTierKey as keyof RewardsConfig['tiers']] || config.tiers['bronze'];
              const multiplier = currentTierConfig.pointMultiplier || 0.01;
              
              // Points earned is (Amount * Multiplier) / Point Value VND
              const pointValueVND = config.pointValueVND || 1000;
              pointsEarned = Math.floor((amount * multiplier) / pointValueVND);

              // Recalculate Tier
              const sortedTiers = Object.values(config.tiers).sort((a, b) => b.minSpent - a.minSpent);
              for (const tier of sortedTiers) {
                if (newSpent >= tier.minSpent) {
                  newTier = tier.tierId;
                  break;
                }
              }
            } else {
              // Fallback legacy calculation
              pointsEarned = Math.floor(amount / 10000);
            }

            await updateDoc(userRef, {
              totalSpent: newSpent,
              totalOrders: newOrders,
              tier: newTier,
              points: increment(pointsEarned)
            });
          }
        } catch (e) {
          console.error("Lỗi khi cộng điểm và nâng hạng:", e);
        }
      }

      toast.success('Cập nhật trạng thái đơn hàng thành công');
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `orders/${orderId}`);
      toast.error('Có lỗi xảy ra khi cập nhật trạng thái đơn hàng');
      throw error;
    }
  };

  return { orders, loading, updateOrderStatus };
}
