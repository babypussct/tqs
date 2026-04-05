import React from 'react';
import { Home, ShoppingBag, ShoppingCart, User } from 'lucide-react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useTheme } from '../contexts/ThemeContext';
import { useAuth } from '../contexts/AuthContext';

interface BottomNavProps {
  cartCount: number;
  onOpenCart: () => void;
}

export default function BottomNav({ cartCount, onOpenCart }: BottomNavProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { theme } = useTheme();
  const { user, login } = useAuth();

  const isDark = theme === 'dark';

  const navItems = [
    { id: 'home', label: 'Trang chủ', path: '/', icon: Home },
    { id: 'shop', label: 'Cửa hàng', path: '/shop', icon: ShoppingBag },
    { id: 'cart', label: 'Giỏ hàng', path: '#cart', icon: ShoppingCart, action: onOpenCart },
    { id: 'profile', label: 'Tài khoản', path: '/profile', icon: User, action: () => {
        if (!user) {
          login();
        } else {
          navigate('/profile');
        }
      } 
    },
  ];

  return (
    <>
      <div 
        className="fixed bottom-0 left-0 right-0 z-50 lg:hidden transition-all duration-300"
        style={{
          background: isDark ? 'rgba(15, 8, 0, 0.85)' : 'rgba(255, 255, 255, 0.85)',
          backdropFilter: 'blur(24px)',
          WebkitBackdropFilter: 'blur(24px)',
          borderTop: isDark ? '1px solid rgba(255, 200, 50, 0.1)' : '1px solid rgba(0, 0, 0, 0.05)',
          paddingBottom: 'env(safe-area-inset-bottom)',
          boxShadow: isDark ? '0 -4px 30px rgba(0, 0, 0, 0.5)' : '0 -4px 30px rgba(0, 0, 0, 0.05)',
        }}
      >
        <div className="flex justify-around items-center h-16 px-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path && item.id !== 'cart';

            return (
              <button
                key={item.id}
                onClick={() => {
                  if (item.action) {
                    item.action();
                  } else if (item.path) {
                    navigate(item.path);
                  }
                }}
                className="relative flex flex-col items-center justify-center w-full h-full gap-1 group"
              >
                {/* Active Indicator (Glowing dot above icon) */}
                <span 
                  className={`absolute top-1 w-1 h-1 rounded-full bg-amber-500 transition-all duration-300 ${
                    isActive ? 'opacity-100 scale-100' : 'opacity-0 scale-0'
                  }`}
                  style={{
                    boxShadow: isActive ? '0 0 8px rgba(245,158,11,0.8)' : 'none'
                  }}
                />

                <div className="relative mt-1">
                  <Icon 
                    className={`w-6 h-6 transition-all duration-300 ${
                      isActive 
                        ? 'text-amber-500 scale-110' 
                        : isDark ? 'text-gray-400 group-hover:text-amber-400' : 'text-gray-500 group-hover:text-amber-600'
                    }`} 
                  />
                  {/* Cart Badge */}
                  {item.id === 'cart' && cartCount > 0 && (
                    <span 
                      className="absolute -top-1.5 -right-2 bg-red-600 text-white text-[10px] font-bold h-4 w-4 rounded-full flex items-center justify-center shadow-md animate-pulse"
                    >
                      {cartCount > 99 ? '99+' : cartCount}
                    </span>
                  )}
                </div>
                <span 
                  className={`text-[10px] font-medium transition-colors duration-300 ${
                    isActive ? 'text-amber-500' : isDark ? 'text-gray-400 group-hover:text-amber-400' : 'text-gray-500 group-hover:text-amber-600'
                  }`}
                >
                  {item.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </>
  );
}
