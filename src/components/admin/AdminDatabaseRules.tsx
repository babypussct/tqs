import React, { useState } from 'react';
import { Database, Copy, CheckCircle2 } from 'lucide-react';
import { toast } from 'sonner';

export default function AdminDatabaseRules() {
  const [copied, setCopied] = useState(false);

  const firestoreRules = `Canonical Firestore Rules are maintained in firestore.rules.

Run the emulator contract suite before deploying:
npm run test:rules

Deploy the reviewed rules file:
firebase deploy --only firestore:rules

Do not paste an allow-all wildcard into production.`;

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(firestoreRules);
      setCopied(true);
      toast.success('Đã sao chép checklist triển khai Rules!');
      setTimeout(() => setCopied(false), 3000);
    } catch (err) {
      toast.error('Lỗi khi sao chép');
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h2 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
          <Database className="w-6 h-6 text-indigo-500" />
          Cấu hình Database Rules
        </h2>
        <p className="text-sm text-slate-500 dark:text-zinc-400 mt-1">
          Rules là mã nguồn được quản lý trong repository, không chỉnh sửa bằng cách dán một
          snippet tạm thời trong Console. Hãy chạy contract tests trên Emulator và review
          thay đổi trước khi deploy.
        </p>
      </div>

      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl overflow-hidden shadow-sm">
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-zinc-800 bg-slate-50 dark:bg-zinc-950">
          <span className="text-sm font-medium text-slate-700 dark:text-zinc-300">Firestore Rules — source-controlled</span>
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
                <Copy className="w-4 h-4" /> Sao chép checklist
              </>
            )}
          </button>
        </div>
        <div className="p-6 bg-slate-900 text-slate-100 overflow-x-auto">
          <pre className="text-sm font-mono leading-relaxed">
            <code>{firestoreRules}</code>
          </pre>
        </div>
      </div>

      <div className="bg-blue-50 dark:bg-blue-500/10 border border-blue-200 dark:border-blue-500/20 rounded-xl p-6">
        <h3 className="font-bold text-blue-900 dark:text-blue-400 mb-4">Quy trình triển khai an toàn:</h3>
        <ol className="list-decimal list-inside space-y-3 text-sm text-blue-800 dark:text-blue-300/80">
          <li>Chạy <code>npm run test:rules</code> và xác nhận toàn bộ scenario pass trên Emulator.</li>
          <li>Review diff của <code>firestore.rules</code>, không có wildcard <code>allow read, write: if true</code>.</li>
          <li>Deploy bằng <code>firebase deploy --only firestore:rules</code> từ commit đã review.</li>
          <li>Chạy smoke test storefront, checkout, admin và order service sau deploy.</li>
          <li>Giữ rollback plan và không deploy Rules restrictive trước khi frontend/API mới đã sẵn sàng.</li>
        </ol>
      </div>
    </div>
  );
}
