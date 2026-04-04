import React, { useState } from 'react';
import { Database, Copy, CheckCircle2 } from 'lucide-react';
import { toast } from 'sonner';

export default function AdminDatabaseRules() {
  const [copied, setCopied] = useState(false);

  const firestoreRules = `rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
  
    // MANG LẠI TOÀN QUYỀN TRUY CẬP CHO HỆ THỐNG (VƯỢT QUA LỖI HẾT HẠN TEST MODE)
    // Quy tắc này đảm bảo tất cả các module: Sản phẩm, Đơn hàng, Phân quyền... đều hoạt động
    match /{document=**} {
      allow read, write: if true;
    }
    
    // Nếu bạn muốn bảo mật cao hơn trong tương lai, 
    // hãy thay thế '{document=**}' bằng các quyền cụ thể từng collection.
  }
}`;

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(firestoreRules);
      setCopied(true);
      toast.success('Đã sao chép mã Rules!');
      setTimeout(() => setCopied(false), 3000);
    } catch (err) {
      toast.error('Lỗi khi sao chép');
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h2 className="text-xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
          <Database className="w-6 h-6 text-indigo-500" />
          Cấu hình Database Rules
        </h2>
        <p className="text-sm text-gray-500 dark:text-zinc-400 mt-1">
          Đây là toàn bộ mã cấu hình Security Rules để sửa lỗi "Missing or insufficient permissions". 
          Hãy sao chép toàn bộ mã bên dưới và dán đè lên nội dung cũ trong tab Rules của Firebase Firestore.
        </p>
      </div>

      <div className="bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-2xl overflow-hidden shadow-sm">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-zinc-800 bg-gray-50 dark:bg-zinc-950">
          <span className="text-sm font-medium text-gray-700 dark:text-zinc-300">Firebase Firestore Security Rules</span>
          <button
            onClick={handleCopy}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium transition-all ${
              copied 
                ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' 
                : 'bg-indigo-50 text-indigo-700 hover:bg-indigo-100 dark:bg-indigo-500/20 dark:text-indigo-400 dark:hover:bg-indigo-500/30'
            }`}
          >
            {copied ? (
              <>
                <CheckCircle2 className="w-4 h-4" /> Đã sao chép
              </>
            ) : (
              <>
                <Copy className="w-4 h-4" /> Sao chép toàn bộ
              </>
            )}
          </button>
        </div>
        <div className="p-6 bg-gray-900 text-gray-100 overflow-x-auto">
          <pre className="text-sm font-mono leading-relaxed">
            <code>{firestoreRules}</code>
          </pre>
        </div>
      </div>

      <div className="bg-blue-50 dark:bg-blue-500/10 border border-blue-200 dark:border-blue-500/20 rounded-2xl p-6">
        <h3 className="font-bold text-blue-900 dark:text-blue-400 mb-4">Các bước thực hiện:</h3>
        <ol className="list-decimal list-inside space-y-3 text-sm text-blue-800 dark:text-blue-300/80">
          <li>Truy cập vào <a href="https://console.firebase.google.com/" target="_blank" rel="noreferrer" className="font-bold underline">Firebase Console</a> và chọn dự án TQS của bạn.</li>
          <li>Tìm và bấm vào <strong>Firestore Database</strong> ở menu cột bên trái.</li>
          <li>Bấm sang thẻ (tab) <strong>Rules</strong>.</li>
          <li>Xóa sạch nội dung cũ trong đó.</li>
          <li>Dán toàn bộ mã vừa sao chép ở trên vào.</li>
          <li>Bấm nút <strong>Publish</strong>. Đợi khoảng vài phút và tải lại trang này.</li>
        </ol>
      </div>
    </div>
  );
}
