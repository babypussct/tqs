import React, { useState, useEffect } from 'react';
import { ShoppingCart, Search, Menu, User as UserIcon, LogOut, Settings, Moon, Sun, ShoppingBag, X, Bell } from 'lucide-react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { useNavigationConfig } from '../hooks/useNavigationConfig';
import { useNotifications } from '../hooks/useNotifications';
import NotificationDrawer from './NotificationDrawer';

interface HeaderProps {
  cartCount: number;
  onOpenCart: () => void;
}

export default function Header({ cartCount, onOpenCart }: HeaderProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, isAdmin, login, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();
  
  // Custom navigation
  const { config: navConfig, loading: navLoading } = useNavigationConfig();
  const { unreadCount } = useNotifications();

  const [searchQuery, setSearchQuery] = useState('');
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [notificationOpen, setNotificationOpen] = useState(false);

  const isHome = location.pathname === '/';

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll();
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Close mobile menu on route change
  useEffect(() => {
    setMobileMenuOpen(false);
    setSearchOpen(false);
  }, [location.pathname]);

  const isTransparent = isHome && !scrolled;

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/shop?q=${encodeURIComponent(searchQuery.trim())}`);
      setSearchOpen(false);
      setSearchQuery('');
    }
  };

  const navLinks = navLoading ? [] : navConfig.links;

  return (
    <>
      <header
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500`}
        style={{
          background: isTransparent
            ? 'linear-gradient(180deg, rgba(0,0,0,0.6) 0%, transparent 100%)'
            : theme === 'dark'
            ? 'rgba(15,8,0,0.85)'
            : 'rgba(255,255,255,0.85)',
          backdropFilter: isTransparent ? 'none' : 'blur(24px)',
          WebkitBackdropFilter: isTransparent ? 'none' : 'blur(24px)',
          boxShadow: isTransparent
            ? 'none'
            : theme === 'dark'
            ? '0 4px 30px rgba(0, 0, 0, 0.5)'
            : '0 4px 30px rgba(0, 0, 0, 0.05)',
          borderBottom: isTransparent
            ? '1px solid transparent'
            : theme === 'dark'
            ? '1px solid rgba(255,200,50,0.1)'
            : '1px solid rgba(0,0,0,0.05)',
        }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16 lg:h-20">
            
            {/* 1. Left: Logo */}
            <div className="flex-1 flex justify-start">
              <div
                className="flex items-center gap-3 cursor-pointer group"
                onClick={() => navigate('/')}
              >
                <div className="relative">
                  <span
                    className="text-2xl lg:text-3xl font-black tracking-tighter uppercase transition-colors duration-300"
                    style={{
                      color: isTransparent ? '#FFD700' : '#DC2626',
                      textShadow: isTransparent
                        ? '0 0 20px rgba(255,215,0,0.8)'
                        : 'none',
                      letterSpacing: '-0.03em',
                    }}
                  >
                    TQS
                  </span>
                  <span
                    className="text-xl lg:text-2xl font-black tracking-tighter uppercase transition-colors duration-300 ml-1"
                    style={{
                      color: isTransparent ? '#fff' : theme === 'dark' ? '#fff' : '#111',
                      letterSpacing: '-0.03em',
                    }}
                  >
                    Store
                  </span>
                </div>
              </div>
            </div>

            {/* 2. Center: Desktop Nav Links */}
            <nav className="hidden lg:flex flex-1 justify-center items-center gap-8 font-medium text-sm">
              {!navLoading && navLinks.map((link) => (
                <button
                  key={link.id}
                  className="relative py-2 px-1 transition-all duration-300 group/nav"
                  style={{
                    color: link.highlight
                      ? '#F59E0B'
                      : isTransparent
                      ? 'rgba(255,255,255,0.9)'
                      : theme === 'dark'
                      ? 'rgba(255,255,255,0.85)'
                      : 'rgba(0,0,0,0.8)',
                    fontWeight: link.highlight ? '700' : '500',
                  }}
                  onClick={() => navigate(link.path)}
                >
                  <span className={`relative z-10 transition-transform duration-300 block group-hover/nav:-translate-y-0.5 ${link.highlight ? 'drop-shadow-[0_0_8px_rgba(245,158,11,0.5)]' : ''}`}>
                    {link.label}
                  </span>
                  
                  {/* Glowing Underline on highlight / hover */}
                  <span
                    className="absolute bottom-0 left-0 right-0 h-[2px] rounded-full scale-x-0 group-hover/nav:scale-x-100 transition-transform duration-300 origin-center"
                    style={{
                      background: link.highlight
                        ? 'linear-gradient(90deg, transparent, #F59E0B, transparent)'
                        : isTransparent
                        ? '#FFD700'
                        : '#DC2626',
                      boxShadow: link.highlight 
                        ? '0 2px 10px rgba(245,158,11,0.8)' 
                        : isTransparent 
                        ? '0 2px 10px rgba(255,215,0,0.8)' 
                        : '0 2px 10px rgba(220,38,38,0.5)'
                    }}
                  />
                </button>
              ))}
            </nav>

            {/* 3. Right: Actions */}
            <div className="flex-1 flex items-center justify-end gap-1 sm:gap-2">
              
              {/* Expanding Search Bar */}
              <div className="relative flex items-center justify-end">
                {searchOpen ? (
                  <form onSubmit={handleSearch} className="flex items-center absolute right-0">
                    <input
                      type="text"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      placeholder="Tìm tên sản phẩm..."
                      autoFocus
                      className="rounded-full py-2 pl-4 pr-10 text-sm focus:outline-none transition-all duration-500 ease-out w-[200px] sm:w-[280px]"
                      style={{
                        background: isTransparent ? 'rgba(0,0,0,0.6)' : theme === 'dark' ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)',
                        border: isTransparent ? '1px solid rgba(255,255,255,0.2)' : theme === 'dark' ? '1px solid rgba(255,255,255,0.1)' : '1px solid rgba(0,0,0,0.1)',
                        color: isTransparent ? '#fff' : theme === 'dark' ? '#fff' : '#111',
                        backdropFilter: 'blur(12px)',
                      }}
                    />
                    <button 
                      type="button" 
                      className={`absolute right-3 p-1 rounded-full hover:bg-black/10 dark:hover:bg-white/10 ${isTransparent || theme === 'dark' ? 'text-gray-300' : 'text-gray-500'}`} 
                      onClick={() => setSearchOpen(false)}
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </form>
                ) : (
                  <button
                    className="p-2 sm:p-2.5 rounded-full transition-all duration-300 hover:scale-110 hover:bg-black/5 dark:hover:bg-white/5"
                    style={{ color: isTransparent ? 'rgba(255,255,255,0.9)' : theme === 'dark' ? '#ccc' : '#444' }}
                    onClick={() => setSearchOpen(true)}
                    title="Tìm kiếm theo tên sản phẩm"
                  >
                    <Search className="h-5 w-5" />
                  </button>
                )}
              </div>

              {/* Theme Toggle */}
              <button
                onClick={toggleTheme}
                className="p-2 sm:p-2.5 rounded-full transition-all duration-300 hover:scale-110 hover:bg-black/5 dark:hover:bg-white/5"
                style={{ color: isTransparent ? 'rgba(255,255,255,0.9)' : theme === 'dark' ? '#ccc' : '#444' }}
                title={theme === 'light' ? 'Chế độ tối' : 'Chế độ sáng'}
              >
                {theme === 'light' ? <Moon className="h-5 w-5" /> : <Sun className="h-5 w-5" />}
              </button>

              {/* Auth User */}
              <div className="relative group hidden lg:block">
                {user ? (
                  <div className="flex items-center gap-2 cursor-pointer p-1 rounded-full transition-all duration-300 hover:scale-105">
                    {user.photoURL ? (
                      <img
                        src={user.photoURL}
                        alt="Avatar"
                        className="w-8 h-8 sm:w-9 sm:h-9 rounded-full border-2 transition-colors duration-300 object-cover"
                        style={{
                          borderColor: isTransparent ? 'rgba(255,215,0,0.8)' : theme === 'dark' ? 'rgba(255,200,50,0.5)' : 'rgba(220,38,38,0.5)',
                        }}
                        referrerPolicy="no-referrer"
                      />
                    ) : (
                      <div
                        className="w-8 h-8 sm:w-9 sm:h-9 rounded-full flex items-center justify-center text-xs font-bold border-2 transition-colors duration-300"
                        style={{
                          background: 'linear-gradient(135deg, #DC2626, #b91c1c)',
                          borderColor: isTransparent ? 'rgba(255,215,0,0.8)' : 'transparent',
                          color: '#fff',
                        }}
                      >
                        {user.displayName?.charAt(0) || user.email?.charAt(0) || 'U'}
                      </div>
                    )}
                    {/* Hover Dropdown */}
                    <div
                      className="absolute right-0 top-full mt-2 w-56 rounded-2xl shadow-2xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-300 z-50 overflow-hidden transform origin-top-right group-hover:scale-100 scale-95"
                      style={{
                        background: theme === 'dark' ? 'rgba(20,10,0,0.85)' : 'rgba(255,255,255,0.85)',
                        backdropFilter: 'blur(24px)',
                        border: theme === 'dark' ? '1px solid rgba(255,255,255,0.1)' : '1px solid rgba(0,0,0,0.1)',
                      }}
                    >
                      <div className="p-4 border-b border-gray-200 dark:border-white/10">
                        <p className="text-sm font-bold truncate text-gray-900 dark:text-white">{user.displayName}</p>
                        <p className="text-xs truncate text-gray-500 dark:text-gray-400 mt-0.5">{user.email}</p>
                      </div>
                      <div className="p-1.5">
                        <button onClick={() => setNotificationOpen(true)} className="w-full text-left px-3 py-2 text-sm font-medium rounded-lg flex items-center justify-between transition-colors text-gray-700 dark:text-gray-200 hover:bg-black/5 dark:hover:bg-white/10 hover:text-amber-500">
                          <div className="flex items-center gap-2">
                             <Bell className="w-4 h-4" /> Thông báo
                          </div>
                          {unreadCount > 0 && (
                            <span className="bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full">
                              {unreadCount}
                            </span>
                          )}
                        </button>
                        <button onClick={() => navigate('/profile')} className="w-full text-left px-3 py-2 text-sm font-medium rounded-lg flex items-center gap-2 transition-colors text-gray-700 dark:text-gray-200 hover:bg-black/5 dark:hover:bg-white/10 hover:text-red-500">
                          <ShoppingBag className="w-4 h-4" /> Đơn hàng của tôi
                        </button>
                        {isAdmin && (
                          <button onClick={() => navigate('/admin')} className="w-full mt-1 text-left px-3 py-2 text-sm font-medium rounded-lg flex items-center gap-2 transition-colors text-gray-700 dark:text-gray-200 hover:bg-amber-500/10 hover:text-amber-500">
                            <Settings className="w-4 h-4" /> Bảng Quản Trị
                          </button>
                        )}
                        <div className="h-px bg-gray-200 dark:bg-white/10 my-1.5 mx-2" />
                        <button onClick={logout} className="w-full text-left px-3 py-2 text-sm font-medium rounded-lg flex items-center gap-2 transition-colors text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10">
                          <LogOut className="w-4 h-4" /> Đăng xuất
                        </button>
                      </div>
                    </div>
                  </div>
                ) : (
                  <button
                    onClick={login}
                    className="p-2 sm:p-2.5 rounded-full transition-all duration-300 hover:scale-110 hover:bg-black/5 dark:hover:bg-white/5"
                    style={{ color: isTransparent ? 'rgba(255,255,255,0.9)' : theme === 'dark' ? '#ccc' : '#444' }}
                    title="Đăng nhập"
                  >
                    <UserIcon className="h-5 w-5" />
                  </button>
                )}
              </div>

              {/* Cart */}
              <button
                onClick={onOpenCart}
                className="hidden lg:flex relative p-2 sm:p-2.5 rounded-full transition-all duration-300 hover:scale-110 hover:bg-black/5 dark:hover:bg-white/5"
                style={{ color: isTransparent ? 'rgba(255,255,255,0.9)' : theme === 'dark' ? '#ccc' : '#444' }}
              >
                <ShoppingCart className="h-5 w-5" />
                {cartCount > 0 && (
                  <span
                    className="absolute top-1 right-1 translate-x-1/4 -translate-y-1/4 text-white text-[10px] sm:text-xs font-bold h-4 w-4 sm:h-5 sm:w-5 rounded-full flex items-center justify-center border transition-colors shadow-lg"
                    style={{
                      background: 'linear-gradient(135deg, #ef4444, #b91c1c)',
                      borderColor: isTransparent ? 'transparent' : theme === 'dark' ? '#0F0800' : '#fff',
                    }}
                  >
                    {cartCount}
                  </span>
                )}
              </button>

              {/* Mobile menu toggle */}
              <button
                className="lg:hidden p-2 sm:p-2.5 rounded-full transition-all duration-300 hover:bg-black/5 dark:hover:bg-white/5"
                style={{ color: isTransparent ? 'rgba(255,255,255,0.9)' : theme === 'dark' ? '#ccc' : '#444' }}
                onClick={() => setMobileMenuOpen(true)}
              >
                <Menu className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Header spacer — only on non-home pages */}
      {!isHome && <div className="h-16 lg:h-20" />}

      {/* Mobile Drawer Navigation */}
      {mobileMenuOpen && (
        <div className="fixed inset-0 z-[60] lg:hidden flex justify-end">
          {/* Backdrop */}
          <div 
            className="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity" 
            onClick={() => setMobileMenuOpen(false)} 
          />
          
          {/* Drawer Sidebar */}
          <div 
            className="relative w-4/5 max-w-sm h-full shadow-2xl flex flex-col transform transition-transform duration-300 border-l"
            style={{
              background: theme === 'dark' ? 'rgba(15,8,0,0.95)' : 'rgba(255,255,255,0.95)',
              backdropFilter: 'blur(24px)',
              borderColor: theme === 'dark' ? 'rgba(255,200,50,0.1)' : 'rgba(0,0,0,0.1)',
            }}
          >
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-white/10">
              <span className="text-xl font-black tracking-tighter uppercase">
                <span className="text-red-600">TQS</span>
                <span className="text-gray-900 dark:text-white ml-1">Store</span>
              </span>
              <button 
                onClick={() => setMobileMenuOpen(false)} 
                className="p-2 -mr-2 rounded-full hover:bg-black/5 dark:hover:bg-white/10 text-gray-500 dark:text-gray-400"
              >
                <X className="h-6 w-6" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto py-4 px-3 space-y-1">
              {!navLoading && navLinks.map((link) => (
                <button
                  key={link.id}
                  className="w-full text-left px-4 py-3.5 rounded-xl text-base font-medium transition-all flex items-center justify-between group"
                  style={{
                    color: link.highlight ? '#F59E0B' : theme === 'dark' ? '#eee' : '#111',
                    background: link.highlight ? 'rgba(245,158,11,0.05)' : 'transparent',
                  }}
                  onClick={() => {
                    navigate(link.path);
                    setMobileMenuOpen(false);
                  }}
                >
                  {link.label}
                  {link.highlight && (
                    <span className="w-1.5 h-1.5 rounded-full bg-amber-500 shadow-[0_0_8px_rgba(245,158,11,0.8)]" />
                  )}
                </button>
              ))}

              <div className="h-px bg-gray-200 dark:bg-white/10 my-4 mx-4" />
              
              <button
                onClick={() => {
                  onOpenCart();
                  setMobileMenuOpen(false);
                }}
                className="w-full text-left px-4 py-3.5 rounded-xl text-base font-medium transition-all flex items-center gap-3 text-gray-700 dark:text-gray-200 hover:bg-black/5 dark:hover:bg-white/5"
              >
                <div className="relative">
                  <ShoppingCart className="h-5 w-5" />
                  {cartCount > 0 && (
                    <span className="absolute -top-1 -right-1 w-2.5 h-2.5 bg-red-500 rounded-full border border-white dark:border-zinc-900 shadow-sm" />
                  )}
                </div>
                Giỏ hàng của bạn ({cartCount})
              </button>
            </div>

            {/* Bottom Auth area */}
            <div className="p-6 border-t border-gray-200 dark:border-white/10">
              {user ? (
                <div className="flex flex-col gap-4">
                  <div className="flex items-center gap-3">
                    {user.photoURL ? (
                      <img src={user.photoURL} alt="" className="w-10 h-10 rounded-full object-cover border border-gray-200 dark:border-zinc-700" referrerPolicy="no-referrer" />
                    ) : (
                      <div className="w-10 h-10 rounded-full bg-indigo-100 text-indigo-700 flex items-center justify-center font-bold text-sm">
                        {user.displayName?.charAt(0) || 'U'}
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-bold text-gray-900 dark:text-white truncate">{user.displayName}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{user.email}</p>
                    </div>
                    <button onClick={logout} className="p-2 text-gray-400 hover:text-red-500 bg-gray-50 dark:bg-zinc-800 rounded-full">
                      <LogOut className="h-4 w-4" />
                    </button>
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <button 
                      onClick={() => {setNotificationOpen(true); setMobileMenuOpen(false);}} 
                      className="flex items-center justify-center gap-2 p-2 rounded-lg bg-gray-50 dark:bg-white/5 hover:bg-gray-100 dark:hover:bg-white/10 transition-colors text-sm font-medium text-gray-700 dark:text-gray-200"
                    >
                      <Bell className="w-4 h-4" />
                      Thông báo
                      {unreadCount > 0 && (
                        <span className="bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full ml-1">
                          {unreadCount}
                        </span>
                      )}
                    </button>
                    <button 
                      onClick={() => {navigate('/profile'); setMobileMenuOpen(false);}} 
                      className="flex items-center justify-center gap-2 p-2 rounded-lg bg-gray-50 dark:bg-white/5 hover:bg-gray-100 dark:hover:bg-white/10 transition-colors text-sm font-medium text-gray-700 dark:text-gray-200"
                    >
                      <ShoppingBag className="w-4 h-4" />
                      Đơn hàng
                    </button>
                    {isAdmin && (
                      <button 
                        onClick={() => {navigate('/admin'); setMobileMenuOpen(false);}} 
                        className="col-span-2 flex items-center justify-center gap-2 p-2 rounded-lg bg-amber-50 dark:bg-amber-500/10 hover:bg-amber-100 dark:hover:bg-amber-500/20 transition-colors text-sm font-medium text-amber-700 dark:text-amber-500"
                      >
                        <Settings className="w-4 h-4" />
                        Bảng Quản Trị
                      </button>
                    )}
                  </div>
                </div>
              ) : (
                <button
                  onClick={() => { login(); setMobileMenuOpen(false); }}
                  className="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-3 rounded-xl transition-colors flex items-center justify-center gap-2"
                >
                  <UserIcon className="h-5 w-5" /> Đăng Nhập
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Notification Drawer */}
      <NotificationDrawer 
        isOpen={notificationOpen} 
        onClose={() => setNotificationOpen(false)} 
      />
    </>
  );
}
