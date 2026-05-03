import React from 'react';

export function PageLoader() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[50vh] space-y-4">
      <div className="relative w-16 h-16">
        <div className="absolute inset-0 rounded-full border-4 border-zinc-200 dark:border-zinc-800"></div>
        <div className="absolute inset-0 rounded-full border-4 border-red-600 border-t-transparent animate-spin"></div>
      </div>
      <p className="text-zinc-500 dark:text-zinc-400 font-medium animate-pulse">
        Đang tải...
      </p>
    </div>
  );
}
