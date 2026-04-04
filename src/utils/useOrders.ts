import { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, doc, updateDoc, serverTimestamp, increment } from 'firebase/firestore';
import { db } from '../firebase';
import { Order } from '../types';
import { handleFirestoreError, OperationType } from './firebaseError';
import { toast } from 'sonner';

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

      // Update Points if delivered
      if (newStatus === 'delivered' && userId && amount) {
        try {
          const pointsEarned = Math.floor(amount / 10000); // 1 point per 10k VND
          await updateDoc(doc(db, 'users', userId), {
            totalSpent: increment(amount),
            points: increment(pointsEarned)
          });
        } catch (e) {
          console.error("Lỗi khi cộng điểm:", e);
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
