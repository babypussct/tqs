import { ArrowRight } from 'lucide-react';
import { HomepageConfig } from '../types';

interface HeroProps {
  data: HomepageConfig['hero'];
}

export default function Hero({ data }: HeroProps) {
  return (
    <div className="bg-white dark:bg-zinc-950 transition-colors duration-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* Main Banner */}
          <div className="lg:col-span-2 relative rounded-2xl overflow-hidden bg-gray-100 dark:bg-zinc-900 aspect-[2/1] lg:aspect-auto lg:h-[400px]">
            {data.main.image && (
              <img 
                src={data.main.image} 
                alt={data.main.title} 
                className="w-full h-full object-cover"
                referrerPolicy="no-referrer"
              />
            )}
            <div className="absolute inset-0 bg-gradient-to-r from-black/60 to-transparent flex flex-col justify-center p-8 sm:p-12">
              {data.main.badge && (
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-red-600 text-white text-xs font-bold mb-4 w-fit uppercase tracking-wider">
                  {data.main.badge}
                </div>
              )}
              <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-white leading-tight mb-4">
                {data.main.title} <br/>
                <span className="text-red-400">{data.main.subtitle}</span>
              </h1>
              {data.main.description && (
                <p className="text-gray-200 mb-6 max-w-md text-sm sm:text-base">
                  {data.main.description}
                </p>
              )}
              {data.main.buttonText && (
                <button className="bg-red-600 hover:bg-red-700 text-white px-6 py-3 rounded-lg font-bold w-fit flex items-center gap-2 transition-colors">
                  {data.main.buttonText} <ArrowRight className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>

          {/* Side Banners */}
          <div className="grid grid-cols-2 lg:grid-cols-1 gap-4 lg:h-[400px]">
            <div className="relative rounded-2xl overflow-hidden bg-gray-100 dark:bg-zinc-900 h-full">
              {data.side1.image && (
                <img 
                  src={data.side1.image} 
                  alt={data.side1.title} 
                  className="w-full h-full object-cover"
                  referrerPolicy="no-referrer"
                />
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent flex flex-col justify-end p-6">
                <h3 className="text-white font-bold text-lg">{data.side1.title}</h3>
                <p className="text-red-400 text-sm font-medium">{data.side1.subtitle}</p>
              </div>
            </div>
            <div className="relative rounded-2xl overflow-hidden bg-gray-100 dark:bg-zinc-900 h-full">
              {data.side2.image && (
                <img 
                  src={data.side2.image} 
                  alt={data.side2.title} 
                  className="w-full h-full object-cover"
                  referrerPolicy="no-referrer"
                />
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent flex flex-col justify-end p-6">
                <h3 className="text-white font-bold text-lg">{data.side2.title}</h3>
                <p className="text-red-400 text-sm font-medium">{data.side2.subtitle}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
