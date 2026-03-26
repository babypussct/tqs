import { useState, useEffect } from 'react';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';

export interface ProductConfig {
  badges: string[];
  types: string[];
}

const DEFAULT_CONFIG: ProductConfig = {
  badges: ['Mới', 'Bán chạy', 'Giảm giá', 'Pre-order'],
  types: ['Boardgame', 'Phụ kiện', 'Mở rộng', 'Khác']
};

export function useProductConfig() {
  const [config, setConfig] = useState<ProductConfig>(DEFAULT_CONFIG);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onSnapshot(doc(db, 'settings', 'productConfig'), (docSnap) => {
      if (docSnap.exists()) {
        setConfig({ ...DEFAULT_CONFIG, ...docSnap.data() });
      } else {
        // Initialize with defaults if not exists
        setDoc(doc(db, 'settings', 'productConfig'), DEFAULT_CONFIG).catch(error => {
          handleFirestoreError(error, OperationType.WRITE, 'settings/productConfig');
        });
      }
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.GET, 'settings/productConfig');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const updateConfig = async (newConfig: ProductConfig) => {
    try {
      await setDoc(doc(db, 'settings', 'productConfig'), newConfig);
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, 'settings/productConfig');
    }
  };

  return { config, loading, updateConfig };
}
