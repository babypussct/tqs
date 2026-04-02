import { useState, useEffect } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';
import { HomepageConfig } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';

export const DEFAULT_HOMEPAGE_CONFIG: HomepageConfig = {
  hero: {
    main: {
      image: 'https://picsum.photos/seed/tamquoc/1200/600',
      badge: 'Hàng Mới Về',
      title: 'Tam Quốc Sát',
      subtitle: 'Tiêu Chuẩn 2024',
      description: 'Sở hữu ngay bộ boardgame chiến thuật đỉnh cao. Cam kết 100% chính hãng, đóng gói chuẩn sưu tầm.',
      buttonText: 'Mua Ngay'
    },
    side1: {
      image: 'https://picsum.photos/seed/quocchien/600/300',
      title: 'Quốc Chiến',
      subtitle: 'Giảm đến 20%'
    },
    side2: {
      image: 'https://picsum.photos/seed/phukien/600/300',
      title: 'Phụ Kiện & Sleeves',
      subtitle: 'Mua kèm giá sốc'
    }
  },
  trustBadges: [
    { icon: 'ShieldCheck', colorClass: 'text-emerald-500', title: 'Hàng Chính Hãng 100%', desc: 'Nhập khẩu trực tiếp, đầy đủ bản quyền.' },
    { icon: 'PackageOpen', colorClass: 'text-amber-500', title: 'Đóng Gói Anti-Móp', desc: '3 lớp bóng khí + Carton cứng. Chuẩn sưu tầm.' },
    { icon: 'Truck', colorClass: 'text-blue-500', title: 'Giao Hàng Siêu Tốc', desc: 'Freeship đơn từ 500k. Giao hỏa tốc 2H.' },
    { icon: 'BookOpen', colorClass: 'text-purple-500', title: 'Hỗ Trợ Luật Chơi', desc: 'Cộng đồng 100k+ thành viên. Giải đáp 24/7.' }
  ],
  sections: [
    { id: '1', title: 'Sản Phẩm Nổi Bật', icon: 'Flame', iconColorClass: 'text-red-500', typeFilter: 'base' },
    { id: '2', title: 'Bản Mở Rộng Mới Nhất', icon: 'Sparkles', iconColorClass: 'text-amber-500', typeFilter: 'expansion' },
    { id: '3', title: 'Phụ Kiện & Sleeves', icon: 'Box', iconColorClass: 'text-blue-500', typeFilter: 'accessory' }
  ]
};

export function useHomepage() {
  const [config, setConfig] = useState<HomepageConfig>(DEFAULT_HOMEPAGE_CONFIG);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onSnapshot(doc(db, 'settings', 'homepage'), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data() as HomepageConfig;
        
        // Randomize Hero Concept if available
        if (data.heroConcepts && data.heroConcepts.length > 0) {
          const activeConcepts = data.heroConcepts.filter(c => c.isActive !== false); // default to true if undefined
          const conceptPool = activeConcepts.length > 0 ? activeConcepts : data.heroConcepts;
          // Only pick randomly once per session/mount to avoid flicker
          const randomIndex = Math.floor(Math.random() * conceptPool.length);
          const chosenConcept = conceptPool[randomIndex];
          data.hero = {
            main: chosenConcept.main,
            side1: chosenConcept.side1,
            side2: chosenConcept.side2,
            effects: chosenConcept.effects
          };
        }
        
        setConfig(data);
      } else {
        setConfig(DEFAULT_HOMEPAGE_CONFIG);
      }
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.GET, 'settings/homepage');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return { config, loading };
}
