import { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, doc, updateDoc, serverTimestamp, increment, getDoc, deleteDoc } from 'firebase/firestore';
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

  const updateOrderStatus = async (order: Order, newStatus: Order['status']) => {
    const { id: orderId, userId, status: oldStatus, earnedPoints } = order;
    const amount = order.finalAmount || order.totalAmount;

    try {
      await updateDoc(doc(db, 'orders', orderId), {
        status: newStatus,
        updatedAt: serverTimestamp()
      });

      // Give points if transitioning TO delivered
      if (newStatus === 'delivered' && oldStatus !== 'delivered' && userId && amount) {
        try {
          const userRef = doc(db, 'users', userId);
          const userSnap = await getDoc(userRef);
          
          if (userSnap.exists()) {
            const userData = userSnap.data();
            const currentSpent = userData.totalSpent || 0;
            const currentOrders = userData.totalOrders || 0;
            const newSpent = currentSpent + amount;
            const newOrders = currentOrders + 1;

            const configRef = doc(db, 'system_settings', 'tiers_config');
            const configSnap = await getDoc(configRef);
            const config: RewardsConfig = configSnap.exists() ? (configSnap.data() as RewardsConfig) : DEFAULT_REWARDS_CONFIG;
            
            let pointsEarned = 0;
            let newTier = userData.tier || 'bronze';

            if (config && config.isActive) {
              const currentTierKey = userData.tier || 'bronze';
              const currentTierConfig = config.tiers[currentTierKey as keyof RewardsConfig['tiers']] || config.tiers['bronze'];
              const multiplier = currentTierConfig.pointMultiplier || 0.01;
              
              const pointValueVND = config.pointValueVND || 1000;
              pointsEarned = Math.floor((amount * multiplier) / pointValueVND);

              const sortedTiers = Object.values(config.tiers).sort((a, b) => b.minSpent - a.minSpent);
              for (const tier of sortedTiers) {
                if (newSpent >= tier.minSpent) {
                  newTier = tier.tierId;
                  break;
                }
              }
            } else {
              pointsEarned = Math.floor(amount / 10000);
            }

            await updateDoc(userRef, {
              totalSpent: newSpent,
              totalOrders: newOrders,
              tier: newTier,
              points: increment(pointsEarned)
            });

            await updateDoc(doc(db, 'orders', orderId), {
              earnedPoints: pointsEarned
            });
          }
        } catch (e) {
          console.error("Lỗi khi cộng điểm và nâng hạng:", e);
        }
      }

      // Rollback points if transitioning AWAY FROM delivered
      if (oldStatus === 'delivered' && newStatus !== 'delivered' && userId) {
        try {
          const userRef = doc(db, 'users', userId);
          const userSnap = await getDoc(userRef);
          
          if (userSnap.exists()) {
            const userData = userSnap.data();
            const currentSpent = userData.totalSpent || 0;
            const currentOrders = userData.totalOrders || 0;
            
            const newSpent = Math.max(0, currentSpent - (amount || 0));
            const newOrders = Math.max(0, currentOrders - 1);
            let newTier = userData.tier || 'bronze';

            const configRef = doc(db, 'system_settings', 'tiers_config');
            const configSnap = await getDoc(configRef);
            
            let finalRollbackPoints = earnedPoints;
            
            if (configSnap.exists()) {
              const config = configSnap.data() as RewardsConfig;
              
              if (finalRollbackPoints === undefined) {
                 if (config.isActive && amount) {
                   const fallbackTierKey = userData.tier || 'bronze';
                   const currentTierConfig = config.tiers[fallbackTierKey as keyof RewardsConfig['tiers']] || config.tiers['bronze'];
                   const multiplier = currentTierConfig.pointMultiplier || 0.01;
                   const pointValueVND = config.pointValueVND || 1000;
                   finalRollbackPoints = Math.floor((amount * multiplier) / pointValueVND);
                 } else if (amount) {
                   finalRollbackPoints = Math.floor(amount / 10000);
                 } else {
                   finalRollbackPoints = 0;
                 }
              }

              if (config.isActive) {
                const sortedTiers = Object.values(config.tiers).sort((a, b) => b.minSpent - a.minSpent);
                newTier = sortedTiers[sortedTiers.length - 1]?.tierId || 'bronze'; // fallback string
                for (const tier of sortedTiers) {
                  if (newSpent >= tier.minSpent) {
                    newTier = tier.tierId;
                    break;
                  }
                }
              }
            } else if (finalRollbackPoints === undefined) {
                finalRollbackPoints = amount ? Math.floor(amount / 10000) : 0;
            }

            await updateDoc(userRef, {
              totalSpent: newSpent,
              totalOrders: newOrders,
              tier: newTier,
              points: increment(-(finalRollbackPoints || 0))
            });

            await updateDoc(doc(db, 'orders', orderId), {
              earnedPoints: 0
            });
          }
        } catch (e) {
          console.error("Lỗi khi trừ điểm và hạ hạng:", e);
        }
      }

      toast.success('Cập nhật trạng thái đơn hàng thành công');
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `orders/${orderId}`);
      toast.error('Có lỗi xảy ra khi cập nhật trạng thái đơn hàng');
      throw error;
    }
  };

  const deleteOrder = async (order: Order) => {
    const { id: orderId, userId, status, earnedPoints } = order;
    const amount = order.finalAmount || order.totalAmount;

    try {
      if (status === 'delivered' && userId) {
        try {
          const userRef = doc(db, 'users', userId);
          const userSnap = await getDoc(userRef);
          
          if (userSnap.exists()) {
            const userData = userSnap.data();
            const currentSpent = userData.totalSpent || 0;
            const currentOrders = userData.totalOrders || 0;
            
            const newSpent = Math.max(0, currentSpent - (amount || 0));
            const newOrders = Math.max(0, currentOrders - 1);
            let newTier = userData.tier || 'bronze';

            const configRef = doc(db, 'system_settings', 'tiers_config');
            const configSnap = await getDoc(configRef);
            
            let finalRollbackPoints = earnedPoints;
            
            if (configSnap.exists()) {
              const config = configSnap.data() as RewardsConfig;
              
              if (finalRollbackPoints === undefined) {
                 if (config.isActive && amount) {
                   const fallbackTierKey = userData.tier || 'bronze';
                   const currentTierConfig = config.tiers[fallbackTierKey as keyof RewardsConfig['tiers']] || config.tiers['bronze'];
                   const multiplier = currentTierConfig.pointMultiplier || 0.01;
                   const pointValueVND = config.pointValueVND || 1000;
                   finalRollbackPoints = Math.floor((amount * multiplier) / pointValueVND);
                 } else if (amount) {
                   finalRollbackPoints = Math.floor(amount / 10000);
                 } else {
                   finalRollbackPoints = 0;
                 }
              }

              if (config.isActive) {
                const sortedTiers = Object.values(config.tiers).sort((a, b) => b.minSpent - a.minSpent);
                newTier = sortedTiers[sortedTiers.length - 1]?.tierId || 'bronze'; // fallback string
                for (const tier of sortedTiers) {
                  if (newSpent >= tier.minSpent) {
                    newTier = tier.tierId;
                    break;
                  }
                }
              }
            } else if (finalRollbackPoints === undefined) {
                finalRollbackPoints = amount ? Math.floor(amount / 10000) : 0;
            }

            await updateDoc(userRef, {
              totalSpent: newSpent,
              totalOrders: newOrders,
              tier: newTier,
              points: increment(-(finalRollbackPoints || 0))
            });
          }
        } catch (e) {
          console.error("Lỗi khi trừ điểm và hạ hạng lúc xoá đơn:", e);
        }
      }

      await deleteDoc(doc(db, 'orders', orderId));
      toast.success('Đã xóa đơn hàng thành công');
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, `orders/${orderId}`);
      toast.error('Có lỗi xảy ra khi xóa đơn hàng');
      throw error;
    }
  };

  return { orders, loading, updateOrderStatus, deleteOrder };
}
