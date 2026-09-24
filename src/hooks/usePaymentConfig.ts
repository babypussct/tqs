import { useState, useEffect } from 'react';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';

export interface PaymentConfig {
  isActive: boolean;
  bankId: string;
  accountNumber: string;
  accountName: string;
  template: string;
  paymentNote: string;
}

const DEFAULT_CONFIG: PaymentConfig = {
  isActive: true,
  bankId: 'MB',
  accountNumber: '0123456789',
  accountName: 'TQS STORE',
  template: 'compact2',
  paymentNote: 'Vui lòng giữ nguyên nội dung chuyển khoản để hệ thống đối soát tự động.',
};

export function usePaymentConfig() {
  const [paymentConfig, setPaymentConfig] = useState<PaymentConfig>(DEFAULT_CONFIG);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onSnapshot(doc(db, 'settings', 'paymentConfig'), (docSnap) => {
      if (docSnap.exists()) {
        setPaymentConfig({ ...DEFAULT_CONFIG, ...docSnap.data() });
      } else {
        // Public reads must never seed protected settings. Admin setup/migration
        // owns creation; storefront uses the in-memory default meanwhile.
        setPaymentConfig(DEFAULT_CONFIG);
      }
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.GET, 'settings/paymentConfig');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const updatePaymentConfig = async (newConfig: PaymentConfig) => {
    try {
      await setDoc(doc(db, 'settings', 'paymentConfig'), newConfig);
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, 'settings/paymentConfig');
    }
  };

  return { paymentConfig, loading, updatePaymentConfig };
}
