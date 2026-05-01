import { useState, useEffect } from 'react';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';

export interface SiteConfig {
  siteTitle: string;
  siteFavicon: string;
  packagingCommitment?: string;
}

const DEFAULT_CONFIG: SiteConfig = {
  siteTitle: 'TQSShop Online - By Otada',
  siteFavicon: '/favicon.ico', // Or whatever default they have
  packagingCommitment: 'Chúng tôi hiểu hộp game nguyên vẹn quan trọng thế nào với người chơi. Mọi đơn hàng đều được bọc <strong>3 lớp xốp bóng khí chống sốc</strong> và đặt trong <strong>hộp carton cứng cáp</strong>.'
};

export function useSiteConfig() {
  const [config, setConfig] = useState<SiteConfig>(DEFAULT_CONFIG);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onSnapshot(doc(db, 'settings', 'siteConfig'), (docSnap) => {
      if (docSnap.exists()) {
        setConfig({ ...DEFAULT_CONFIG, ...docSnap.data() });
      } else {
        // Initialize with defaults if not exists
        setDoc(doc(db, 'settings', 'siteConfig'), DEFAULT_CONFIG).catch(error => {
          handleFirestoreError(error, OperationType.WRITE, 'settings/siteConfig');
        });
      }
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.GET, 'settings/siteConfig');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const updateConfig = async (newConfig: SiteConfig) => {
    try {
      await setDoc(doc(db, 'settings', 'siteConfig'), newConfig);
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, 'settings/siteConfig');
    }
  };

  return { config, loading, updateConfig };
}
