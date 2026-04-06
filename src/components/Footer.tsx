import React from 'react';
import { Facebook, Youtube, Mail, MapPin, Phone, ChevronRight, ShieldCheck, Gamepad2, PackageCheck } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useFooterConfig } from '../hooks/useFooterConfig';

export default function Footer() {
  const navigate = useNavigate();
  const { config, loading } = useFooterConfig();

  if (loading) return null; // Avoid rendering unstyled empty footer initially

  return (
    <footer className="bg-white dark:bg-zinc-950 border-t border-gray-200 dark:border-zinc-800 pt-16 pb-8 mt-auto transition-colors duration-300 relative overflow-hidden">
      {/* Background subtle gradients */}
      <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-gray-200 dark:via-zinc-800 to-transparent" />
      <div className="absolute -top-24 -right-24 w-96 h-96 bg-red-500/5 dark:bg-red-500/10 blur-[100px] rounded-full pointer-events-none" />
      <div className="absolute -bottom-24 -left-24 w-96 h-96 bg-amber-500/5 dark:bg-amber-500/10 blur-[100px] rounded-full pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 lg:gap-8 mb-16">
          
          {/* Column 1: Brand Info */}
          <div className="lg:col-span-1">
            <div 
              className="flex items-center gap-1 cursor-pointer mb-6"
              onClick={() => window.scrollTo(0, 0)}
            >
              <div className="relative">
                <span className="text-3xl font-black tracking-tighter text-red-600 dark:text-red-500 uppercase drop-shadow-sm">TQS</span>
                <span className="text-2xl font-black tracking-tighter text-gray-900 dark:text-white uppercase ml-1">Store</span>
              </div>
            </div>
            <p className="text-gray-500 dark:text-zinc-400 text-sm leading-relaxed mb-6">
              {config.brandDescription}
            </p>
            <div className="flex items-center gap-4">
              {config.socialLinks?.facebook && (
                <a href={config.socialLinks.facebook} target="_blank" rel="noreferrer" className="w-10 h-10 rounded-full flex items-center justify-center bg-gray-100 dark:bg-zinc-900 text-gray-500 dark:text-zinc-400 hover:bg-red-50 dark:hover:bg-red-500/10 hover:text-red-600 dark:hover:text-red-500 transition-all duration-300 hover:-translate-y-1 hover:shadow-lg">
                  <Facebook className="w-5 h-5" />
                </a>
              )}
              {config.socialLinks?.youtube && (
                <a href={config.socialLinks.youtube} target="_blank" rel="noreferrer" className="w-10 h-10 rounded-full flex items-center justify-center bg-gray-100 dark:bg-zinc-900 text-gray-500 dark:text-zinc-400 hover:bg-red-50 dark:hover:bg-red-500/10 hover:text-red-600 dark:hover:text-red-500 transition-all duration-300 hover:-translate-y-1 hover:shadow-lg">
                  <Youtube className="w-5 h-5" />
                </a>
              )}
              {config.socialLinks?.email && (
                <a href={config.socialLinks.email.includes('@') ? `mailto:${config.socialLinks.email}` : config.socialLinks.email} target="_blank" rel="noreferrer" className="w-10 h-10 rounded-full flex items-center justify-center bg-gray-100 dark:bg-zinc-900 text-gray-500 dark:text-zinc-400 hover:bg-red-50 dark:hover:bg-red-500/10 hover:text-red-600 dark:hover:text-red-500 transition-all duration-300 hover:-translate-y-1 hover:shadow-lg">
                  <Mail className="w-5 h-5" />
                </a>
              )}
            </div>
          </div>

          {/* Column 2: Danh Mục */}
          <div>
            <h4 className="text-gray-900 dark:text-white font-bold mb-6 uppercase tracking-wider text-sm flex items-center gap-2">
              <Gamepad2 className="w-4 h-4 text-amber-500" />
              Danh Mục Sản Phẩm
            </h4>
            <ul className="space-y-4 text-sm">
              {config.categoryLinks?.map((item, idx) => (
                <li key={idx}>
                  <button 
                    onClick={() => { navigate(item.path); window.scrollTo(0, 0); }} 
                    className="group flex items-center text-gray-500 dark:text-zinc-400 hover:text-red-600 dark:hover:text-red-400 transition-colors duration-300"
                  >
                    <ChevronRight className="w-4 h-4 mr-1 opacity-0 -ml-5 group-hover:opacity-100 group-hover:ml-0 transition-all duration-300" />
                    <span className={item.special ? 'text-amber-600 dark:text-amber-500 font-medium' : ''}>
                      {item.label}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          </div>

          {/* Column 3: Chính Sách */}
          <div>
            <h4 className="text-gray-900 dark:text-white font-bold mb-6 uppercase tracking-wider text-sm flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-emerald-500" />
              Hỗ Trợ Khách Hàng
            </h4>
            <ul className="space-y-4 text-sm">
              {config.policyLinks?.map((item, idx) => (
                <li key={idx}>
                  <a 
                    href={item.path} 
                    className="group flex items-center text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white transition-colors duration-300"
                  >
                    <ChevronRight className="w-4 h-4 mr-1 opacity-0 -ml-5 group-hover:opacity-100 group-hover:ml-0 transition-all duration-300" />
                    <span>{item.label}</span>
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Column 4: Liên Hệ & Address */}
          <div>
            <h4 className="text-gray-900 dark:text-white font-bold mb-6 uppercase tracking-wider text-sm flex items-center gap-2">
              <MapPin className="w-4 h-4 text-red-500" />
              Thông Tin Liên Hệ
            </h4>
            <ul className="space-y-4 text-sm text-gray-500 dark:text-zinc-400">
              {config.contactInfo?.address && (
                <li className="flex items-start gap-3 group">
                  <MapPin className="w-5 h-5 flex-shrink-0 text-gray-400 dark:text-zinc-500 mt-0.5 group-hover:text-red-500 transition-colors" />
                  <span className="leading-relaxed group-hover:text-gray-900 dark:group-hover:text-white transition-colors">
                    {config.contactInfo.address}<br/>
                    {config.contactInfo.workingHours}
                  </span>
                </li>
              )}
              {config.contactInfo?.phone && (
                <li className="flex items-center gap-3 group">
                  <Phone className="w-5 h-5 flex-shrink-0 text-gray-400 dark:text-zinc-500 group-hover:text-amber-500 transition-colors" />
                  <div>
                    <span className="block text-xs text-gray-400 dark:text-zinc-500 group-hover:text-gray-500 transition-colors">Hotline tư vấn</span>
                    <a href={`tel:${config.contactInfo.phone.replace(/[^0-9]/g, '')}`} className="text-gray-900 dark:text-white font-medium hover:text-red-500 transition-colors block mt-0.5">{config.contactInfo.phone}</a>
                  </div>
                </li>
              )}
              {config.contactInfo?.email && (
                <li className="flex items-center gap-3 group">
                  <Mail className="w-5 h-5 flex-shrink-0 text-gray-400 dark:text-zinc-500 group-hover:text-indigo-500 transition-colors" />
                  <div>
                    <span className="block text-xs text-gray-400 dark:text-zinc-500 group-hover:text-gray-500 transition-colors">Email hỗ trợ</span>
                    <a href={`mailto:${config.contactInfo.email}`} className="text-gray-900 dark:text-white font-medium hover:text-red-500 transition-colors block mt-0.5">{config.contactInfo.email}</a>
                  </div>
                </li>
              )}
            </ul>
          </div>

        </div>

        {/* Bottom Bar: Copyright & Trusted Badges */}
        <div className="border-t border-gray-200 dark:border-zinc-800/50 pt-8 flex flex-col md:flex-row justify-between items-center gap-6">
          <div className="flex flex-col md:flex-row items-center gap-2 md:gap-6 text-sm text-gray-400 dark:text-zinc-500">
            <p>{config.bottomText}</p>
            {config.badges?.map((badge, idx) => (
              <React.Fragment key={idx}>
                {idx > 0 && <div className="hidden md:block w-1 h-1 bg-gray-300 dark:bg-zinc-700 rounded-full" />}
                <div className="flex items-center gap-1.5 hover:text-emerald-600 dark:hover:text-emerald-500 transition-colors cursor-default">
                  <ShieldCheck className="w-4 h-4 text-emerald-500" />
                  <span className="font-medium text-gray-600 dark:text-zinc-400">{badge}</span>
                </div>
              </React.Fragment>
            ))}
          </div>
          
          {/* Payment Methods */}
          <div className="flex flex-wrap justify-center items-center gap-2 opacity-60 hover:opacity-100 transition-opacity duration-300">
            {config.paymentMethods?.map((method, idx) => (
              <div key={idx} className="h-8 px-3 bg-white dark:bg-zinc-900 rounded border border-gray-200 dark:border-zinc-700 flex items-center justify-center text-[10px] font-bold text-indigo-600 dark:text-indigo-400 shadow-sm uppercase tracking-wider">
                {method}
              </div>
            ))}
          </div>
        </div>
      </div>
    </footer>
  );
}
