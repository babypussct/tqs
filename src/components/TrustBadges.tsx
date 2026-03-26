import * as Icons from 'lucide-react';
import { TrustBadge } from '../types';

interface TrustBadgesProps {
  badges: TrustBadge[];
}

export default function TrustBadges({ badges }: TrustBadgesProps) {
  return (
    <div className="bg-white dark:bg-zinc-950 border-b border-gray-200 dark:border-zinc-800 py-8 transition-colors duration-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-8">
          {badges.map((badge, idx) => {
            const Icon = (Icons as any)[badge.icon] || Icons.CheckCircle;
            return (
              <div key={idx} className="flex flex-col sm:flex-row items-center sm:items-start text-center sm:text-left gap-3 sm:gap-4 p-4 rounded-xl bg-gray-50 dark:bg-zinc-900 border border-gray-100 dark:border-zinc-800 hover:border-red-100 dark:hover:border-red-500/30 hover:bg-red-50/50 dark:hover:bg-red-500/5 transition-colors">
                <div className="p-3 bg-white dark:bg-zinc-800 rounded-full shadow-sm shrink-0">
                  <Icon className={`h-8 w-8 ${badge.colorClass}`} />
                </div>
                <div>
                  <h3 className="text-gray-900 dark:text-zinc-100 font-bold text-sm sm:text-base mb-1">{badge.title}</h3>
                  <p className="text-gray-500 dark:text-zinc-400 text-xs sm:text-sm leading-relaxed hidden sm:block">{badge.desc}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
