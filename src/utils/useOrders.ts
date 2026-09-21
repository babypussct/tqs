import { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';
import { Order } from '../types';
import { toast } from 'sonner';
import { postOrderCommand } from './orderApi';
import { handleFirestoreError, OperationType } from './firebaseError';

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
    try {
      await postOrderCommand({
        orderId: order.id,
        targetStatus: newStatus,
      });
      toast.success('Cập nhật trạng thái đơn hàng thành công');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Có lỗi xảy ra khi cập nhật trạng thái đơn hàng';
      toast.error(message);
      throw error;
    }
  };

  const deleteOrder = async (order: Order) => {
    try {
      await postOrderCommand({
        orderId: order.id,
        targetStatus: 'cancelled',
        actionType: 'cancel_order',
        cancelReason: 'admin_cancelled',
      });
      toast.success('Đã hủy đơn hàng');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Có lỗi xảy ra khi hủy đơn hàng';
      toast.error(message);
      throw error;
    }
  };

  return { orders, loading, updateOrderStatus, deleteOrder };
}
