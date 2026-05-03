import { useEffect } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';
import { toast } from 'sonner';

const STORAGE_KEY = 'tqs_sync_version';

export function useDeltaSync() {
  useEffect(() => {
    // Chỉ lắng nghe đúng 1 document siêu nhỏ này
    const unsubscribe = onSnapshot(doc(db, 'system', 'version'), (docSnap) => {
      if (docSnap.exists()) {
        const serverVersion = docSnap.data().productsUpdated || 0;
        const localVersionStr = localStorage.getItem(STORAGE_KEY);
        const localVersion = localVersionStr ? parseInt(localVersionStr, 10) : 0;

        // Nếu mới vào web lần đầu, lưu version nhưng không báo cáo F5
        if (!localVersionStr) {
          localStorage.setItem(STORAGE_KEY, serverVersion.toString());
          return;
        }

        // Nếu server có dữ liệu mới (timestamp lớn hơn local)
        if (serverVersion > localVersion) {
          toast('📢 Cập nhật Sản phẩm mới!', {
            description: 'Dữ liệu cửa hàng đã có sự thay đổi (giá mới, tồn kho,...).',
            action: {
              label: 'Tải lại trang',
              onClick: () => {
                localStorage.setItem(STORAGE_KEY, serverVersion.toString());
                window.location.reload();
              },
            },
            duration: Infinity, // Giữ thông báo cho đến khi user click
            dismissible: false,
          });
        }
      }
    });

    return () => unsubscribe();
  }, []);
}
