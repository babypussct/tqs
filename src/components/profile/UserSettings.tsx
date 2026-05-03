import React from 'react';
import { LogOut } from 'lucide-react';
import { toast } from 'sonner';

interface UserSettingsProps {
  user: any;
  logout: () => Promise<void>;
}

export default function UserSettings({ user, logout }: UserSettingsProps) {
  return (
    <div className="bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-3xl p-6 md:p-8 shadow-sm max-w-2xl animate-fade-in transition-all">
       <h2 className="text-2xl font-black text-gray-900 dark:text-white mb-6 border-b border-gray-200 dark:border-zinc-800 pb-4">Tài khoản & Thiết lập</h2>
       
       <div className="space-y-4">
          <div className="p-4 border border-gray-200 dark:border-zinc-800 rounded-2xl flex items-center justify-between">
             <div>
                <h3 className="font-bold text-gray-900 dark:text-white">Email Đăng nhập</h3>
                <p className="text-sm font-medium text-gray-500 dark:text-zinc-400 mt-1">{user.email}</p>
             </div>
             <div className="hidden sm:block text-xs font-bold bg-gray-100 dark:bg-zinc-800 text-gray-500 px-3 py-1 rounded-full uppercase tracking-wider">
                Bảo mật qua Google
             </div>
          </div>
          
          <div className="pt-8">
             <button 
                onClick={() => {
                   if (window.confirm('Bạn có chắc chắn muốn đăng xuất?')) {
                      logout().then(() => {
                         toast.success('Đã đăng xuất thành công');
                      });
                   }
                }}
                className="w-full sm:w-auto flex items-center justify-center gap-2 bg-red-50 hover:bg-red-100 dark:bg-red-500/10 dark:hover:bg-red-500/20 text-red-600 dark:text-red-500 px-6 py-3.5 rounded-xl font-bold transition-colors border-2 border-red-100 dark:border-red-500/20"
             >
                <LogOut className="w-5 h-5" />
                Đăng xuất khỏi thiết bị này
             </button>
             <p className="text-sm text-gray-500 dark:text-zinc-400 mt-4 font-medium text-center sm:text-left">Để bảo vệ thông tin cá nhân, vui lòng đăng xuất khi sử dụng thiết bị công cộng.</p>
          </div>
       </div>
    </div>
  );
}
