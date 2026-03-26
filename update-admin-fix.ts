import fs from 'fs';

let content = fs.readFileSync('src/components/AdminDashboard.tsx', 'utf-8');

// Fix the messy replacements
content = content.replace(/text-gray-900 dark:text-gray-400 dark:text-zinc-500/g, 'text-gray-500 dark:text-zinc-500');
content = content.replace(/hover:text-gray-700 dark:text-zinc-300/g, 'hover:text-gray-700 dark:hover:text-zinc-300');
content = content.replace(/text-gray-900 dark:text-gray-900 dark:text-white/g, 'text-gray-900 dark:text-white');
content = content.replace(/text-gray-900 dark:text-gray-900 dark:text-zinc-50/g, 'text-gray-900 dark:text-zinc-50');
content = content.replace(/text-gray-700 dark:text-gray-700 dark:text-zinc-300/g, 'text-gray-700 dark:text-zinc-300');
content = content.replace(/text-gray-500 dark:text-gray-500 dark:text-zinc-400/g, 'text-gray-500 dark:text-zinc-400');
content = content.replace(/text-gray-400 dark:text-gray-400 dark:text-zinc-500/g, 'text-gray-400 dark:text-zinc-500');
content = content.replace(/text-gray-400 dark:text-gray-400 dark:text-zinc-600/g, 'text-gray-400 dark:text-zinc-600');
content = content.replace(/text-gray-300 dark:text-gray-300 dark:text-zinc-700/g, 'text-gray-300 dark:text-zinc-700');

fs.writeFileSync('src/components/AdminDashboard.tsx', content);
console.log('AdminDashboard.tsx fixed successfully.');
