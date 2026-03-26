import fs from 'fs';

let content = fs.readFileSync('src/components/AdminDashboard.tsx', 'utf-8');

// Replace background colors
content = content.replace(/bg-zinc-900\/50/g, 'bg-white dark:bg-zinc-900/50');
content = content.replace(/bg-zinc-900\/30/g, 'bg-white dark:bg-zinc-900/30');
content = content.replace(/bg-zinc-900\/80/g, 'bg-gray-50 dark:bg-zinc-900/80');
content = content.replace(/bg-zinc-900/g, 'bg-white dark:bg-zinc-900');
content = content.replace(/bg-zinc-800\/50/g, 'bg-gray-100 dark:bg-zinc-800/50');
content = content.replace(/bg-zinc-800\/30/g, 'bg-gray-50 dark:bg-zinc-800/30');
content = content.replace(/bg-zinc-800/g, 'bg-gray-100 dark:bg-zinc-800');

// Replace text colors
content = content.replace(/text-white/g, 'text-gray-900 dark:text-white');
content = content.replace(/text-zinc-50/g, 'text-gray-900 dark:text-zinc-50');
content = content.replace(/text-zinc-300/g, 'text-gray-700 dark:text-zinc-300');
content = content.replace(/text-zinc-400/g, 'text-gray-500 dark:text-zinc-400');
content = content.replace(/text-zinc-500/g, 'text-gray-400 dark:text-zinc-500');
content = content.replace(/text-zinc-600/g, 'text-gray-400 dark:text-zinc-600');
content = content.replace(/text-zinc-700/g, 'text-gray-300 dark:text-zinc-700');

// Replace border colors
content = content.replace(/border-zinc-800\/50/g, 'border-gray-200 dark:border-zinc-800/50');
content = content.replace(/border-zinc-800/g, 'border-gray-200 dark:border-zinc-800');
content = content.replace(/border-zinc-700/g, 'border-gray-300 dark:border-zinc-700');

// Replace hover colors
content = content.replace(/hover:bg-zinc-800\/30/g, 'hover:bg-gray-50 dark:hover:bg-zinc-800/30');
content = content.replace(/hover:bg-zinc-800/g, 'hover:bg-gray-100 dark:hover:bg-zinc-800');
content = content.replace(/hover:bg-zinc-700/g, 'hover:bg-gray-200 dark:hover:bg-zinc-700');
content = content.replace(/hover:text-white/g, 'hover:text-gray-900 dark:hover:text-white');
content = content.replace(/hover:text-zinc-300/g, 'hover:text-gray-700 dark:hover:text-zinc-300');

// Fix some specific cases
content = content.replace(/bg-white dark:bg-white dark:bg-zinc-900/g, 'bg-white dark:bg-zinc-900');
content = content.replace(/text-gray-900 dark:text-gray-900 dark:text-white/g, 'text-gray-900 dark:text-white');
content = content.replace(/border-gray-200 dark:border-gray-200 dark:border-zinc-800/g, 'border-gray-200 dark:border-zinc-800');

fs.writeFileSync('src/components/AdminDashboard.tsx', content);
console.log('AdminDashboard.tsx updated successfully.');
