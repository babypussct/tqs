import { useState, useEffect } from 'react';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { ShippingConfig } from '../types';
import { FIRESTORE_PATHS } from '../shared/constants/firestorePaths';

export function useShippingConfig() {
  const [config, setConfig] = useState<ShippingConfig>({
    isActive: true,
    defaultFee: 30000,
    freeshipThreshold: 500000,
    freeshipProductIds: []
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onSnapshot(doc(db, ...FIRESTORE_PATHS.systemSettings.shipping), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        setConfig({
          isActive: data.isActive ?? true,
          defaultFee: data.defaultFee ?? 30000,
          freeshipThreshold: data.freeshipThreshold !== undefined ? data.freeshipThreshold : 500000,
          freeshipProductIds: data.freeshipProductIds || []
        });
      }
      setLoading(false);
    }, (error) => {
      console.error("Error fetching shipping config:", error);
      setLoading(false);
    });

    return () => unsub();
  }, []);

  const updateShippingConfig = async (newConfig: Partial<ShippingConfig>) => {
    try {
      await setDoc(doc(db, ...FIRESTORE_PATHS.systemSettings.shipping), { ...config, ...newConfig }, { merge: true });
    } catch (error) {
      console.error("Error updating shipping config:", error);
      throw error;
    }
  };

  return { shippingConfig: config, loading, updateShippingConfig };
}
