import { useState, useEffect } from 'react';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';

export interface NavLink {
  id: string;
  label: string;
  path: string;
  highlight: boolean;
}

export interface NavigationConfig {
  links: NavLink[];
}

const DEFAULT_CONFIG: NavigationConfig = {
  links: [
    { id: 'all-products', label: 'Tất Cả Sản Phẩm', path: '/shop', highlight: false },
    { id: 'base', label: 'Bản Cơ Bản', path: '/shop?type=base', highlight: false },
    { id: 'expansion', label: 'Bản Mở Rộng', path: '/shop?type=expansion', highlight: false },
    { id: 'accessory', label: 'Phụ Kiện & Sleeves', path: '/shop?type=accessory', highlight: true },
  ]
};

export function useNavigationConfig() {
  const [config, setConfig] = useState<NavigationConfig>(DEFAULT_CONFIG);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onSnapshot(doc(db, 'settings', 'navigationConfig'), (docSnap) => {
      if (docSnap.exists()) {
        setConfig({ ...DEFAULT_CONFIG, ...docSnap.data() });
      } else {
        // Initialize with defaults if not exists
        setDoc(doc(db, 'settings', 'navigationConfig'), DEFAULT_CONFIG).catch(error => {
          handleFirestoreError(error, OperationType.WRITE, 'settings/navigationConfig');
        });
      }
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.GET, 'settings/navigationConfig');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const updateConfig = async (newConfig: NavigationConfig) => {
    try {
      await setDoc(doc(db, 'settings', 'navigationConfig'), newConfig);
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, 'settings/navigationConfig');
    }
  };

  return { config, loading, updateConfig };
}
