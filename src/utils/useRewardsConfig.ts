import { useState, useEffect } from 'react';
import { doc, onSnapshot, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { RewardsConfig } from '../types';

export const DEFAULT_REWARDS_CONFIG: RewardsConfig = {
  isActive: true,
  pointValueVND: 1000,
  minPointsToUse: 10,
  maxDiscountPercentage: 50,
  tiers: {
    bronze: {
      tierId: 'bronze',
      name: 'Thành viên Đồng',
      minSpent: 0,
      pointMultiplier: 0.01,
      benefits: ['Tích lũy 1% giá trị đơn hàng thành điểm thưởng'],
    },
    silver: {
      tierId: 'silver',
      name: 'Thành viên Bạc',
      minSpent: 5000000,
      pointMultiplier: 0.02,
      benefits: ['Tích lũy 2% giá trị đơn hàng thành điểm thưởng', 'Ưu đãi đặc biệt vào sinh nhật'],
    },
    gold: {
      tierId: 'gold',
      name: 'Thành viên Vàng',
      minSpent: 15000000,
      pointMultiplier: 0.03,
      benefits: ['Tích lũy 3% giá trị đơn hàng thành điểm thưởng', 'Miễn phí giao hàng cho đơn từ 500k'],
    },
    diamond: {
      tierId: 'diamond',
      name: 'Thành viên Kim Cương',
      minSpent: 30000000,
      pointMultiplier: 0.05,
      benefits: ['Tích lũy 5% giá trị đơn hàng thành điểm thưởng', 'Quyền ưu tiên mua sớm (Early Access)', 'Quà tặng tri ân hàng năm'],
    },
  },
};

export function useRewardsConfig() {
  const [config, setConfig] = useState<RewardsConfig>(DEFAULT_REWARDS_CONFIG);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const configRef = doc(db, 'system_settings', 'tiers_config');
    
    // Listen for changes in real-time
    const unsubscribe = onSnapshot(configRef, (docSnapshot) => {
      if (docSnapshot.exists()) {
        setConfig(docSnapshot.data() as RewardsConfig);
      } else {
        // If document doesn't exist, we might need to initialize it
        // but we'll just use default for now.
        setConfig(DEFAULT_REWARDS_CONFIG);
      }
      setLoading(false);
    }, (err) => {
      console.error("Error fetching rewards config:", err);
      setError(err.message);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const updateConfig = async (newConfig: RewardsConfig) => {
    try {
      const configRef = doc(db, 'system_settings', 'tiers_config');
      await setDoc(configRef, newConfig);
      return true;
    } catch (err: any) {
      console.error("Error updating rewards config:", err);
      setError(err.message);
      return false;
    }
  };

  return { config, updateConfig, loading, error };
}
