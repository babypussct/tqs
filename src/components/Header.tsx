import React, { useState, useEffect } from 'react';
import { ShoppingCart, Search, Menu, User as UserIcon, LogOut, Settings, Moon, Sun, ShoppingBag, X } from 'lucide-react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { useProductConfig } from '../hooks/useProductConfig';

interface HeaderProps {
  cartCount: number;
  onOpenCart: () => void;
}

export default function Header({ cartCount, onOpenCart }: HeaderProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, isAdmin, login, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const { config: productConfig } = useProductConfig();
  const [searchQuery, setSearchQuery] = useState('');
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);

  const isHome = location.pathname === '/';

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 60);
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
    }
  };

  const navLinks = [
    { label: 'Tất Cả Sản Phẩm', path: '/shop' },
    { label: 'Bản Cơ Bản', path: '/shop?type=base' },
    { label: 'Bản Mở Rộng', path: '/shop?type=expansion' },
    { label: 'Phụ Kiện & Sleeves', path: '/shop?type=accessory', highlight: true },
  ];

  return (
    <>
      <header
        className="fixed top-0 left-0 right-0 z-50 transition-all duration-500"
        style={{
          background: isTransparent
            ? 'linear-gradient(180deg, rgba(0,0,0,0.7) 0%, rgba(0,0,0,0.2) 70%, transparent 100%)'
            : theme === 'dark'
            ? 'rgba(10,5,0,0.97)'
            : 'rgba(255,255,255,0.97)',
          backdropFilter: isTransparent ? 'none' : 'blur(16px)',
          boxShadow: isTransparent
            ? 'none'
            : '0 1px 24px rgba(0,0,0,0.15)',
          borderBottom: isTransparent
            ? 'none'
            : theme === 'dark'
            ? '1px solid rgba(255,200,50,0.08)'
            : '1px solid rgba(0,0,0,0.08)',
        }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16 lg:h-18">
            {/* Logo */}
            <div
              className="flex items-center gap-3 cursor-pointer group"
              onClick={() => navigate('/')}
            >
              {/* Corner decorative accent */}
              <div className="hidden lg:block relative">
                <span
                  className="text-2xl font-black tracking-tighter uppercase transition-all duration-300"
                  style={{
                    color: isTransparent ? '#FFD700' : '#DC2626',
                    textShadow: isTransparent
                      ? '0 0 20px rgba(255,215,0,0.8), 0 0 40px rgba(255,180,0,0.4)'
                      : 'none',
                    letterSpacing: '-0.03em',
                  }}
                >
                  TQS
                </span>
                <span
                  className="text-2xl font-black tracking-tighter uppercase transition-all duration-300"
                  style={{
                    color: isTransparent ? '#fff' : theme === 'dark' ? '#fff' : '#111',
                    letterSpacing: '-0.03em',
                    textShadow: isTransparent ? '0 1px 8px rgba(0,0,0,0.6)' : 'none',
                  }}
                >
                  Store
                </span>
              </div>
              {/* Mobile logo */}
              <span className="lg:hidden text-xl font-black tracking-tighter uppercase">
                <span style={{ color: isTransparent ? '#FFD700' : '#DC2626' }}>TQS</span>
                <span style={{ color: isTransparent ? '#fff' : theme === 'dark' ? '#fff' : '#111' }}>Store</span>
              </span>
            </div>

            {/* Desktop Nav */}
            <nav className="hidden lg:flex items-center gap-6 font-medium text-sm">
              {navLinks.map((link) => (
                <button
                  key={link.path}
                  className="relative py-1 px-1 transition-all duration-300 group/nav"
                  style={{
                    color: link.highlight
                      ? '#F59E0B'
                      : isTransparent
                      ? 'rgba(255,255,255,0.88)'
                      : theme === 'dark'
                      ? 'rgba(255,255,255,0.85)'
                      : 'rgba(0,0,0,0.8)',
                    fontWeight: link.highlight ? '700' : '500',
                    textShadow: isTransparent ? '0 1px 4px rgba(0,0,0,0.7)' : 'none',
                  }}
                  onClick={() => navigate(link.path)}
                  onMouseEnter={(e) => {
                    if (!link.highlight) {
                      (e.currentTarget as HTMLButtonElement).style.color = isTransparent
                        ? '#FFD700'
                        : '#DC2626';
                    }
                  }}
                  onMouseLeave={(e) => {
                    if (!link.highlight) {
                      (e.currentTarget as HTMLButtonElement).style.color = isTransparent
                        ? 'rgba(255,255,255,0.88)'
                        : theme === 'dark'
                        ? 'rgba(255,255,255,0.85)'
                        : 'rgba(0,0,0,0.8)';
                    }
                  }}
                >
                  {link.label}
                  {/* Hover underline with gold glow */}
                  <span
                    className="absolute bottom-0 left-0 right-0 h-[1px] scale-x-0 group-hover/nav:scale-x-100 transition-transform duration-300"
                    style={{
                      background: link.highlight
                        ? 'linear-gradient(90deg, transparent, #F59E0B, transparent)'
                        : isTransparent
                        ? 'linear-gradient(90deg, transparent, #FFD700, transparent)'
                        : 'linear-gradient(90deg, transparent, #DC2626, transparent)',
                    }}
                  />
                </button>
              ))}
              {productConfig.types?.slice(0, 2).map((type) => (
                <button
                  key={type}
                  className="py-1 px-1 transition-all duration-300 hover:text-red-500"
                  style={{
                    color: isTransparent
                      ? 'rgba(255,255,255,0.88)'
                      : theme === 'dark'
                      ? 'rgba(255,255,255,0.85)'
                      : 'rgba(0,0,0,0.8)',
                    textShadow: isTransparent ? '0 1px 4px rgba(0,0,0,0.7)' : 'none',
                  }}
                  onClick={() => navigate(`/shop?type=${type}`)}
                >
                  {type}
                </button>
              ))}
            </nav>

            {/* Actions */}
            <div className="flex items-center gap-2">
              {/* Search Desktop */}
              {!searchOpen ? (
                <button
                  className="p-2 rounded-full transition-all duration-300 hover:scale-110"
                  style={{ color: isTransparent ? 'rgba(255,255,255,0.85)' : theme === 'dark' ? '#aaa' : '#555' }}
                  onClick={() => setSearchOpen(true)}
                  title="Tìm kiếm"
                >
                  <Search className="h-5 w-5" />
                </button>
              ) : (
                <form onSubmit={handleSearch} className="flex items-center relative">
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Tìm kiếm..."
                    autoFocus
                    className="rounded-full py-2 pl-4 pr-10 text-sm w-64 focus:outline-none transition-all"
                    style={{
                      background: isTransparent ? 'rgba(0,0,0,0.5)' : theme === 'dark' ? 'rgba(60,30,0,0.6)' : 'rgba(240,240,240,0.95)',
                      border: isTransparent ? '1px solid rgba(255,200,50,0.3)' : '1px solid rgba(200,30,30,0.3)',
                      color: isTransparent ? '#fff' : theme === 'dark' ? '#fff' : '#111',
                      backdropFilter: 'blur(8px)',
                    }}
                  />
                  <button type="button" className="absolute right-3 text-gray-400 hover:text-red-400" onClick={() => setSearchOpen(false)}>
                    <X className="h-4 w-4" />
                  </button>
                </form>
              )}

              {/* Theme Toggle */}
              <button
                onClick={toggleTheme}
                className="p-2 rounded-full transition-all duration-300 hover:scale-110"
                style={{ color: isTransparent ? 'rgba(255,255,255,0.85)' : theme === 'dark' ? '#aaa' : '#555' }}
                title={theme === 'light' ? 'Chế độ tối' : 'Chế độ sáng'}
              >
                {theme === 'light' ? <Moon className="h-5 w-5" /> : <Sun className="h-5 w-5" />}
              </button>

              {/* Auth */}
              <div className="relative group">
                {user ? (
                  <div className="flex items-center gap-2 cursor-pointer p-1 rounded-full transition-all duration-300">
                    {user.photoURL ? (
                      <img
                        src={user.photoURL}
                        alt="Avatar"
                        className="w-8 h-8 rounded-full border-2 transition-all duration-300"
                        style={{
                          borderColor: isTransparent ? 'rgba(255,215,0,0.6)' : 'rgba(220,38,38,0.5)',
                          boxShadow: isTransparent ? '0 0 10px rgba(255,215,0,0.4)' : 'none',
                        }}
                        referrerPolicy="no-referrer"
                      />
                    ) : (
                      <div
                        className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold border-2 transition-all duration-300"
                        style={{
                          background: '#DC2626',
                          borderColor: isTransparent ? 'rgba(255,215,0,0.6)' : 'transparent',
                          color: '#fff',
                        }}
                      >
                        {user.displayName?.charAt(0) || user.email?.charAt(0) || 'U'}
                      </div>
                    )}
                    {/* Dropdown */}
                    <div
                      className="absolute right-0 top-full mt-3 w-52 rounded-2xl shadow-2xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-50 overflow-hidden"
                      style={{
                        background: theme === 'dark' ? 'rgba(15,8,0,0.97)' : 'rgba(255,255,255,0.97)',
                        backdropFilter: 'blur(20px)',
                        border: '1px solid rgba(255,200,50,0.15)',
                        boxShadow: '0 20px 60px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,200,50,0.1)',
                      }}
                    >
                      <div className="p-3 border-b" style={{ borderColor: 'rgba(255,200,50,0.1)' }}>
                        <p className="text-sm font-bold truncate" style={{ color: theme === 'dark' ? '#fff' : '#111' }}>{user.displayName}</p>
                        <p className="text-xs truncate" style={{ color: '#888' }}>{user.email}</p>
                      </div>
                      <button onClick={() => navigate('/profile')} className="w-full text-left px-4 py-2.5 text-sm flex items-center gap-2 transition-all hover:bg-red-500/10 hover:text-red-500" style={{ color: theme === 'dark' ? '#ccc' : '#333' }}>
                        <ShoppingBag className="w-4 h-4" /> Đơn hàng của tôi
                      </button>
                      {isAdmin && (
                        <button onClick={() => navigate('/admin')} className="w-full text-left px-4 py-2.5 text-sm flex items-center gap-2 transition-all hover:bg-amber-500/10 hover:text-amber-500 border-t" style={{ color: theme === 'dark' ? '#ccc' : '#333', borderColor: 'rgba(255,200,50,0.1)' }}>
                          <Settings className="w-4 h-4" /> Quản trị
                        </button>
                      )}
                      <button onClick={logout} className="w-full text-left px-4 py-2.5 text-sm flex items-center gap-2 border-t text-red-500 hover:bg-red-500/10 transition-all" style={{ borderColor: 'rgba(255,200,50,0.1)' }}>
                        <LogOut className="w-4 h-4" /> Đăng xuất
                      </button>
                    </div>
                  </div>
                ) : (
                  <button
                    onClick={login}
                    className="p-2 rounded-full transition-all duration-300 hover:scale-110"
                    style={{ color: isTransparent ? 'rgba(255,255,255,0.85)' : theme === 'dark' ? '#aaa' : '#555' }}
                    title="Đăng nhập"
                  >
                    <UserIcon className="h-5 w-5" />
                  </button>
                )}
              </div>

              {/* Cart */}
              <button
                onClick={onOpenCart}
                className="relative p-2 rounded-full transition-all duration-300 hover:scale-110"
                style={{ color: isTransparent ? 'rgba(255,255,255,0.85)' : theme === 'dark' ? '#aaa' : '#555' }}
              >
                <ShoppingCart className="h-5 w-5" />
                {cartCount > 0 && (
                  <span
                    className="absolute -top-1 -right-1 text-white text-[10px] font-bold h-5 w-5 rounded-full flex items-center justify-center border-2 transition-colors"
                    style={{
                      background: '#DC2626',
                      borderColor: isTransparent ? 'transparent' : theme === 'dark' ? '#0A0500' : '#fff',
                      boxShadow: '0 0 8px rgba(220,38,38,0.6)',
                    }}
                  >
                    {cartCount}
                  </span>
                )}
              </button>

              {/* Mobile menu toggle */}
              <button
                className="lg:hidden p-2 rounded-full transition-all duration-300"
                style={{ color: isTransparent ? 'rgba(255,255,255,0.85)' : theme === 'dark' ? '#aaa' : '#555' }}
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              >
                {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
              </button>
            </div>
          </div>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div
            className="lg:hidden px-4 pb-4 pt-2"
            style={{
              background: theme === 'dark' ? 'rgba(10,5,0,0.98)' : 'rgba(255,255,255,0.98)',
              backdropFilter: 'blur(20px)',
              borderTop: '1px solid rgba(255,200,50,0.1)',
            }}
          >
            {navLinks.map((link) => (
              <button
                key={link.path}
                className="block w-full text-left py-3 px-2 text-sm font-medium border-b transition-colors hover:text-red-500"
                style={{
                  color: link.highlight ? '#F59E0B' : theme === 'dark' ? '#ccc' : '#333',
                  borderColor: 'rgba(255,200,50,0.08)',
                }}
                onClick={() => navigate(link.path)}
              >
                {link.label}
              </button>
            ))}
          </div>
        )}
      </header>

      {/* Header spacer — only on non-home pages */}
      {!isHome && <div style={{ height: '64px' }} />}
    </>
  );
}
