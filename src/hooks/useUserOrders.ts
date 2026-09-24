import { useEffect, useState } from 'react';
import { collection, onSnapshot, orderBy, query, where } from 'firebase/firestore';
import { db } from '../firebase';
import type { Order } from '../types';
import { normalizeOrder } from '../shared/orders/orderView';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';

export function useUserOrders(userId: string | undefined) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(Boolean(userId));

  useEffect(() => {
    if (!userId) {
      setOrders([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    const orderQuery = query(
      collection(db, 'orders'),
      where('userId', '==', userId),
      orderBy('createdAt', 'desc'),
    );
    return onSnapshot(orderQuery, (snapshot) => {
      setOrders(snapshot.docs.map((item) => normalizeOrder(item.data(), item.id)));
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.LIST, 'orders');
      setLoading(false);
    });
  }, [userId]);

  return { orders, loading };
}
