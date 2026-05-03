import { useState, useEffect } from 'react';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';

export interface FooterLink {
  label: string;
  path: string;
  special?: boolean;
}

export interface FooterConfig {
  brandDescription: string;
  socialLinks: {
    facebook: string;
    youtube: string;
    email: string;
  };
  categoryLinks: FooterLink[];
  policyLinks: FooterLink[];
  contactInfo: {
    address: string;
    workingHours: string;
    phone: string;
    email: string;
  };
  bottomText: string;
  badges: string[];
  paymentMethods: string[];
}

const DEFAULT_CONFIG: FooterConfig = {
  brandDescription: 'Hệ thống phân phối boardgame Tam Quốc Sát chính hãng lớn nhất Việt Nam. Cam kết chất lượng, đóng gói chuẩn sưu tầm.',
  socialLinks: {
    facebook: 'https://facebook.com',
    youtube: 'https://youtube.com',
    email: 'support@tqsstore.com',
  },
  categoryLinks: [
    { label: 'Bản Cơ Bản', path: '/shop?category=co-ban' },
    { label: 'Bản Mở Rộng', path: '/shop?category=mo-rong' },
    { label: 'Quốc Chiến', path: '/shop?category=quoc-chien' },
    { label: 'Phụ Kiện & Sleeves', path: '/shop?category=phu-kien', special: true },
  ],
  policyLinks: [
    { label: 'Chính sách bảo hành', path: '#' },
    { label: 'Chính sách đổi trả (Anti-Móp)', path: '#' },
    { label: 'Giao hàng & Thanh toán', path: '#' },
    { label: 'Hướng dẫn luật chơi cơ bản', path: '#' },
  ],
  contactInfo: {
    address: 'Hà Nội, Việt Nam.',
    workingHours: '(Mở cửa: 9:00 - 18:00 từ Thứ 2 - T7)',
    phone: '0987.654.321',
    email: 'support@tqsstore.com',
  },
  bottomText: '© 2024 TQS Store. All rights reserved.',
  badges: ['Đóng gói chuẩn sưu tầm.', 'Việt hóa 100%'],
  paymentMethods: ['COD', 'VNPay', 'VISA'],
};

export function useFooterConfig() {
  const [config, setConfig] = useState<FooterConfig>(DEFAULT_CONFIG);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onSnapshot(doc(db, 'settings', 'footerConfig'), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data() as Partial<FooterConfig>;
        
        // Merge nested objects properly instead of simple spread
        setConfig({
          ...DEFAULT_CONFIG,
          ...data,
          socialLinks: { ...DEFAULT_CONFIG.socialLinks, ...data.socialLinks },
          contactInfo: { ...DEFAULT_CONFIG.contactInfo, ...data.contactInfo },
          categoryLinks: data.categoryLinks || DEFAULT_CONFIG.categoryLinks,
          policyLinks: data.policyLinks || DEFAULT_CONFIG.policyLinks,
          badges: data.badges || DEFAULT_CONFIG.badges,
          paymentMethods: data.paymentMethods || DEFAULT_CONFIG.paymentMethods,
        });
      } else {
        // Initialize with defaults if not exists
        setDoc(doc(db, 'settings', 'footerConfig'), DEFAULT_CONFIG).catch(error => {
          handleFirestoreError(error, OperationType.WRITE, 'settings/footerConfig');
        });
      }
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.GET, 'settings/footerConfig');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const updateConfig = async (newConfig: FooterConfig) => {
    try {
      await setDoc(doc(db, 'settings', 'footerConfig'), newConfig);
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, 'settings/footerConfig');
      throw error;
    }
  };

  return { config, loading, updateConfig };
}
