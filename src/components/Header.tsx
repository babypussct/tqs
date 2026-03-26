import { useState } from 'react';
import { ShoppingCart, Search, Menu, ChevronDown, User as UserIcon, LogOut, Settings, Moon, Sun, ShoppingBag } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { useProductConfig } from '../hooks/useProductConfig';

interface HeaderProps {
  cartCount: number;
  onOpenCart: () => void;
}

export default function Header({ cartCount, onOpenCart }: HeaderProps) {
  const navigate = useNavigate();
  const { user, isAdmin, login, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const { config: productConfig } = useProductConfig();
  const [searchQuery, setSearchQuery] = useState('');

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/shop?q=${encodeURIComponent(searchQuery.trim())}`);
    }
  };

  return (
    <header className="sticky top-0 z-50 w-full bg-white dark:bg-zinc-950 border-b border-gray-200 dark:border-zinc-800 text-gray-800 dark:text-zinc-100 shadow-sm transition-colors duration-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <div 
            className="flex items-center gap-2 cursor-pointer"
            onClick={() => navigate('/')}
          >
            <Menu className="h-6 w-6 lg:hidden" />
            <span className="text-2xl font-black tracking-tighter text-red-600 uppercase">TQS<span className="text-gray-900 dark:text-white">Store</span></span>
          </div>

          {/* Desktop Mega Menu */}
          <nav className="hidden lg:flex items-center gap-8 font-medium text-sm">
            <div 
              className="group relative cursor-pointer py-5"
              onClick={() => navigate('/shop')}
            >
              <span className="flex items-center gap-1 hover:text-red-500 dark:hover:text-red-400 transition-colors">
                Tất Cả Sản Phẩm
              </span>
            </div>
            <div className="group relative cursor-pointer py-5" onClick={() => navigate('/shop?type=base')}>
              <span className="flex items-center gap-1 hover:text-red-500 dark:hover:text-red-400 transition-colors">
                Bản Cơ Bản
              </span>
            </div>
            <div className="cursor-pointer hover:text-red-500 dark:hover:text-red-400 transition-colors py-5" onClick={() => navigate('/shop?type=expansion')}>
              Bản Mở Rộng
            </div>
            <div className="cursor-pointer text-amber-500 hover:text-amber-400 transition-colors py-5 font-bold" onClick={() => navigate('/shop?type=accessory')}>
              Phụ Kiện & Sleeves
            </div>
            {productConfig.types?.slice(0, 3).map(type => (
              <div key={type} className="cursor-pointer hover:text-red-500 dark:hover:text-red-400 transition-colors py-5" onClick={() => navigate(`/shop?type=${type}`)}>
                {type}
              </div>
            ))}
          </nav>

          {/* Actions */}
          <div className="flex items-center gap-4">
            <form onSubmit={handleSearch} className="hidden md:flex items-center relative">
              <input 
                type="text" 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Tìm kiếm tướng, bản mở rộng..." 
                className="bg-gray-100 dark:bg-zinc-900 border border-transparent rounded-full py-2 pl-4 pr-10 text-sm focus:outline-none focus:border-red-500 focus:bg-white dark:focus:bg-zinc-950 w-72 transition-all dark:text-zinc-100 dark:placeholder-zinc-500"
              />
              <button type="submit" className="absolute right-3 text-gray-500 dark:text-zinc-400 hover:text-red-500 transition-colors">
                <Search className="h-4 w-4" />
              </button>
            </form>
            <button className="p-2 hover:bg-gray-100 dark:hover:bg-zinc-900 text-gray-600 dark:text-zinc-400 rounded-full transition-colors md:hidden">
              <Search className="h-5 w-5" />
            </button>
            
            <button 
              onClick={toggleTheme}
              className="p-2 hover:bg-gray-100 dark:hover:bg-zinc-900 text-gray-600 dark:text-zinc-400 rounded-full transition-colors"
              title={theme === 'light' ? 'Chế độ tối' : 'Chế độ sáng'}
            >
              {theme === 'light' ? <Moon className="h-5 w-5" /> : <Sun className="h-5 w-5" />}
            </button>

            {/* Auth UI */}
            <div className="relative group">
              {user ? (
                <div className="flex items-center gap-2 cursor-pointer p-1.5 hover:bg-gray-100 dark:hover:bg-zinc-900 rounded-full transition-colors">
                {user.photoURL ? (
                  <img src={user.photoURL} alt="Avatar" className="w-7 h-7 rounded-full border border-gray-200 dark:border-zinc-700" referrerPolicy="no-referrer" />
                ) : (
                  <div className="w-7 h-7 rounded-full bg-gray-200 dark:bg-zinc-700 flex items-center justify-center text-gray-500 dark:text-zinc-400 text-xs font-bold">
                    {user.displayName?.charAt(0) || user.email?.charAt(0) || 'U'}
                  </div>
                )}
                  <div className="absolute right-0 top-full mt-2 w-48 bg-white dark:bg-zinc-900 border border-gray-100 dark:border-zinc-800 rounded-xl shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-50 overflow-hidden">
                    <div className="p-3 border-b border-gray-100 dark:border-zinc-800 bg-gray-50 dark:bg-zinc-950">
                      <p className="text-sm font-medium text-gray-900 dark:text-zinc-100 truncate">{user.displayName}</p>
                      <p className="text-xs text-gray-500 dark:text-zinc-400 truncate">{user.email}</p>
                    </div>
                    <button onClick={() => navigate('/profile')} className="w-full text-left px-4 py-2.5 text-sm text-gray-700 dark:text-zinc-300 hover:bg-gray-50 dark:hover:bg-zinc-800 hover:text-red-600 dark:hover:text-red-400 flex items-center gap-2">
                      <ShoppingBag className="w-4 h-4" /> Đơn hàng của tôi
                    </button>
                    {isAdmin && (
                      <button onClick={() => navigate('/admin')} className="w-full text-left px-4 py-2.5 text-sm text-gray-700 dark:text-zinc-300 hover:bg-gray-50 dark:hover:bg-zinc-800 hover:text-red-600 dark:hover:text-red-400 flex items-center gap-2 border-t border-gray-100 dark:border-zinc-800">
                        <Settings className="w-4 h-4" /> Quản trị
                      </button>
                    )}
                    <button onClick={logout} className="w-full text-left px-4 py-2.5 text-sm text-red-600 dark:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 flex items-center gap-2 border-t border-gray-100 dark:border-zinc-800">
                      <LogOut className="w-4 h-4" /> Đăng xuất
                    </button>
                  </div>
                </div>
              ) : (
                <button onClick={login} className="p-2 hover:bg-gray-100 dark:hover:bg-zinc-900 text-gray-600 dark:text-zinc-400 rounded-full transition-colors relative group" title="Đăng nhập">
                  <UserIcon className="h-5 w-5" />
                </button>
              )}
            </div>

            <button 
              onClick={onOpenCart}
              className="p-2 hover:bg-gray-100 dark:hover:bg-zinc-900 text-gray-600 dark:text-zinc-400 rounded-full transition-colors relative"
            >
              <ShoppingCart className="h-5 w-5" />
              {cartCount > 0 && (
                <span className="absolute -top-1 -right-1 bg-red-600 text-white text-[10px] font-bold h-5 w-5 rounded-full flex items-center justify-center border-2 border-white dark:border-zinc-950">
                  {cartCount}
                </span>
              )}
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
