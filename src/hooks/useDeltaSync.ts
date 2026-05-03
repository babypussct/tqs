import { useEffect } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';

const STORAGE_KEY = 'tqs_sync_version';

interface DeltaSyncOptions {
  onDataUpdate?: () => void;
}

export function useDeltaSync(options: DeltaSyncOptions = {}) {
  useEffect(() => {
    // Chỉ lắng nghe đúng 1 document siêu nhỏ này
    const unsubscribe = onSnapshot(doc(db, 'system', 'version'), (docSnap) => {
      if (docSnap.exists()) {
        const serverVersion = docSnap.data().productsUpdated || 0;
        const localVersionStr = localStorage.getItem(STORAGE_KEY);

        // Nếu mới vào web lần đầu, lưu version nhưng không báo
        if (!localVersionStr) {
          localStorage.setItem(STORAGE_KEY, serverVersion.toString());
          return;
        }

        const localVersion = parseInt(localVersionStr, 10);

        // Nếu server có dữ liệu mới (timestamp lớn hơn local)
        if (serverVersion > localVersion) {
          localStorage.setItem(STORAGE_KEY, serverVersion.toString());
          options.onDataUpdate?.();
        }
      }
    });

    return () => unsubscribe();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps
}

