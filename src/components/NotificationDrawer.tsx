import React from 'react';
import { X, Bell, Package, Tag, Info, CheckCircle2 } from 'lucide-react';
import { useNotifications, Notification } from '../hooks/useNotifications';
import { useTheme } from '../contexts/ThemeContext';
import { useNavigate } from 'react-router-dom';

interface NotificationDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function NotificationDrawer({ isOpen, onClose }: NotificationDrawerProps) {
  const { theme } = useTheme();
  const navigate = useNavigate();
  const { notifications, unreadCount, markAsRead, markAllAsRead, loading } = useNotifications();

  if (!isOpen) return null;

  const handleNotificationClick = (notif: Notification) => {
    if (!notif.isRead) {
      markAsRead(notif.id);
    }
    if (notif.link) {
      navigate(notif.link);
      onClose();
    }
  };

  const getIcon = (type: string) => {
    switch (type) {
      case 'order': return <Package className="w-5 h-5 text-blue-500" />;
      case 'promo': return <Tag className="w-5 h-5 text-amber-500" />;
      default: return <Info className="w-5 h-5 text-gray-500" />;
    }
  };

  const formatTime = (isoString?: string) => {
    if (!isoString) return '';
    const date = new Date(isoString);
    return new Intl.DateTimeFormat('vi-VN', {
      hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit', year: 'numeric'
    }).format(date);
  };

  return (
    <div className="fixed inset-0 z-[70] flex justify-end">
      {/* Backdrop */}
      <div 
        className="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity" 
        onClick={onClose} 
      />
      
      {/* Drawer Sidebar */}
      <div 
        className="relative w-80 max-w-[90vw] h-full shadow-2xl flex flex-col transform transition-transform duration-300 border-l"
        style={{
          background: theme === 'dark' ? 'rgba(15,8,0,0.95)' : 'rgba(255,255,255,0.95)',
          backdropFilter: 'blur(24px)',
          borderColor: theme === 'dark' ? 'rgba(255,200,50,0.1)' : 'rgba(0,0,0,0.1)',
        }}
      >
        <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-white/10">
          <div className="flex items-center gap-2">
            <Bell className="w-5 h-5 text-gray-700 dark:text-gray-200" />
            <h2 className="text-lg font-bold text-gray-900 dark:text-white">Thông báo</h2>
            {unreadCount > 0 && (
              <span className="bg-red-500 text-white text-xs font-bold px-2 py-0.5 rounded-full">
                {unreadCount}
              </span>
            )}
          </div>
          <button 
            onClick={onClose} 
            className="p-1.5 rounded-full hover:bg-black/5 dark:hover:bg-white/10 text-gray-500 dark:text-gray-400"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {unreadCount > 0 && (
          <div className="px-4 py-2 border-b border-gray-100 dark:border-white/5 flex justify-end">
             <button 
               onClick={() => markAllAsRead()}
               className="text-xs font-medium text-amber-600 hover:text-amber-700 dark:text-amber-500 dark:hover:text-amber-400 flex items-center gap-1 transition-colors"
             >
               <CheckCircle2 className="w-3.5 h-3.5" />
               Đánh dấu tất cả là đã đọc
             </button>
          </div>
        )}

        <div className="flex-1 overflow-y-auto">
          {loading ? (
             <div className="p-8 text-center text-gray-500 dark:text-gray-400">
               <div className="animate-spin w-6 h-6 border-2 border-amber-500 border-t-transparent rounded-full mx-auto mb-2"></div>
               Đang tải...
             </div>
          ) : notifications.length === 0 ? (
            <div className="p-8 text-center flex flex-col items-center justify-center h-full text-gray-500 dark:text-gray-400">
              <Bell className="w-12 h-12 mb-3 opacity-20" />
              <p>Chưa có thông báo nào</p>
            </div>
          ) : (
            <div className="divide-y divide-gray-100 dark:divide-white/5">
              {notifications.map((notif) => (
                <button
                  key={notif.id}
                  onClick={() => handleNotificationClick(notif)}
                  className={`w-full text-left p-4 hover:bg-black/5 dark:hover:bg-white/5 transition-colors relative ${!notif.isRead ? 'bg-amber-50/50 dark:bg-amber-500/5' : ''}`}
                >
                  {!notif.isRead && (
                    <span className="absolute left-2 top-1/2 -translate-y-1/2 w-1.5 h-1.5 bg-amber-500 rounded-full" />
                  )}
                  <div className={`flex gap-3 ${!notif.isRead ? 'ml-3' : ''}`}>
                    <div className="flex-shrink-0 mt-0.5">
                      {getIcon(notif.type)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className={`text-sm font-semibold truncate ${!notif.isRead ? 'text-gray-900 dark:text-white' : 'text-gray-700 dark:text-gray-300'}`}>
                        {notif.title}
                      </p>
                      <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5 line-clamp-2">
                        {notif.message}
                      </p>
                      <p className="text-xs text-gray-400 dark:text-gray-500 mt-1.5">
                        {formatTime(notif.createdAt)}
                      </p>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
