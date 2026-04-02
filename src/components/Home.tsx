import { useNavigate } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import * as Icons from 'lucide-react';
import Hero from './Hero';
import TrustBadges from './TrustBadges';
import ProductCard from './ProductCard';
import { useProducts } from '../hooks/useProducts';
import { useHomepage } from '../hooks/useHomepage';
import { Product } from '../types';

interface HomeProps {
  onAddToCart: (product: Product) => void;
}

export default function Home({ onAddToCart }: HomeProps) {
  const navigate = useNavigate();
  const { products, loading: productsLoading } = useProducts(true);
  const { config, loading: configLoading } = useHomepage();

  const loading = productsLoading || configLoading;

  const activeConcepts = config.heroConcepts?.filter(c => c.isActive) || [];
  const activeHeroData = activeConcepts.length > 0
    ? activeConcepts[Math.floor(Math.random() * activeConcepts.length)] // Randomly pick one active concept
    : config.hero; // Fallback to regular hero if none active

  return (
    <div className="bg-gray-50 dark:bg-zinc-950 pb-12 transition-colors duration-200">
      {!configLoading && <Hero data={activeHeroData as typeof config.hero} />}
      {!configLoading && (
        <div className="mt-0">
          <TrustBadges badges={config.trustBadges} />
        </div>
      )}

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 space-y-12">
        {loading ? (
          <div className="flex justify-center items-center py-20 text-gray-500 dark:text-zinc-400">
            Đang tải dữ liệu...
          </div>
        ) : (
          <>
            {config.sections.map((section) => {
              const Icon = (Icons as any)[section.icon] || Icons.Star;
              const sectionProducts = section.typeFilter === 'all' 
                ? products.slice(0, 4)
                : products.filter(p => p.type === section.typeFilter).slice(0, 4);

              if (sectionProducts.length === 0) return null;

              return (
                <section key={section.id} className="bg-white dark:bg-zinc-900 rounded-2xl p-6 shadow-sm border border-gray-100 dark:border-zinc-800 transition-colors duration-200">
                  <div className="flex items-center justify-between mb-6 border-b border-gray-100 dark:border-zinc-800 pb-4">
                    <div className="flex items-center gap-2">
                      <Icon className={`h-6 w-6 ${section.iconColorClass}`} />
                      <h2 className="text-xl font-bold text-gray-900 dark:text-white uppercase tracking-tight">{section.title}</h2>
                    </div>
                    <button 
                      onClick={() => navigate('/shop')}
                      className="text-red-600 dark:text-red-500 hover:text-red-700 dark:hover:text-red-400 text-sm font-medium flex items-center gap-1 transition-colors"
                    >
                      Xem tất cả <ArrowRight className="h-4 w-4" />
                    </button>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    {sectionProducts.map(product => (
                      <ProductCard key={product.id} product={product} onClick={(id) => navigate(`/product/${id}`)} onAddToCart={onAddToCart} />
                    ))}
                  </div>
                </section>
              );
            })}
          </>
        )}
      </div>
    </div>
  );
}
