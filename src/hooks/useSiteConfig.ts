import { useState, useEffect } from 'react';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';

export interface SiteConfig {
  siteTitle: string;
  siteFavicon: string;
}

const DEFAULT_CONFIG: SiteConfig = {
  siteTitle: 'My Google AI Studio App',
  siteFavicon: '/favicon.ico' // Or whatever default they have
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
