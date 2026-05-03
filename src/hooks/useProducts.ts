import { useState, useEffect } from 'react';
import { collection, onSnapshot, query, where, getDocs, getDocsFromCache, getDocsFromServer } from 'firebase/firestore';
import { db } from '../firebase';
import { Product } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';

const CACHE_KEY = 'tqs_products_last_fetch';

export function useProducts(activeOnly = true) {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let q: any = collection(db, 'products');
    
    if (activeOnly) {
      q = query(q, where('isActive', '==', true));
    }

    // Dành cho Admin (cần realtime cập nhật liên tục để sửa lỗi, quản lý tồn kho)
    if (!activeOnly) {
      const unsubscribe = onSnapshot(q, (snapshot) => {
        const prods: Product[] = [];
        snapshot.forEach((doc) => prods.push({ id: doc.id, ...doc.data() } as Product));
        prods.sort((a, b) => (b.createdAt?.toMillis?.() || 0) - (a.createdAt?.toMillis?.() || 0));
        setProducts(prods);
        setLoading(false);
      });
      return () => unsubscribe();
    }

    // Dành cho Khách hàng (Sử dụng cơ chế Delta Sync - Đọc 1 lần)
    let isMounted = true;
    const fetchProducts = async () => {
      try {
        const lastFetchStr = sessionStorage.getItem(CACHE_KEY);
        const now = Date.now();
        // Force fetch server nếu quá 1 tiếng không lấy dữ liệu hoặc lần đầu vào web
        const shouldFetchServer = !lastFetchStr || (now - parseInt(lastFetchStr)) > 3600000;

        let snapshot;
        if (shouldFetchServer) {
          snapshot = await getDocsFromServer(q);
          sessionStorage.setItem(CACHE_KEY, now.toString());
        } else {
          // Lấy từ Local Cache (0 Reads Firestore)
          try {
            snapshot = await getDocsFromCache(q);
            if (snapshot.empty) snapshot = await getDocsFromServer(q); // Fallback nếu cache rỗng
          } catch {
            snapshot = await getDocsFromServer(q);
          }
        }

        if (!isMounted) return;

        const prods: Product[] = [];
        snapshot.forEach((doc) => prods.push({ id: doc.id, ...doc.data() } as Product));
        prods.sort((a, b) => (b.createdAt?.toMillis?.() || 0) - (a.createdAt?.toMillis?.() || 0));
        
        setProducts(prods);
      } catch (error) {
        handleFirestoreError(error, OperationType.LIST, 'products');
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    fetchProducts();
    return () => { isMounted = false; };
  }, [activeOnly]);

  return { products, loading };
}
