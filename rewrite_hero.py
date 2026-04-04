import os
import re

file_path = "src/components/admin/AdminHeroEditor.tsx"
with open(file_path, "r") as f:
    content = f.read()

# Switch accents
content = content.replace('amber-500', 'indigo-500')
content = content.replace('amber-400', 'indigo-600 dark:text-indigo-400')
content = content.replace('text-amber-400/60', 'text-indigo-500')

# Component Colors
content = content.replace('bg-zinc-800/60 border border-zinc-700/60 rounded-xl px-4 py-2.5 text-sm text-white outline-none focus:border-indigo-500/70 focus:bg-zinc-800 transition-all placeholder-zinc-600', 'w-full bg-slate-50 dark:bg-zinc-900 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-sm text-slate-900 dark:text-white outline-none focus:border-indigo-500 transition-all placeholder-slate-400 dark:placeholder-zinc-600')

content = content.replace('bg-zinc-800/40 border border-zinc-700/50', 'bg-slate-50 dark:bg-zinc-900/40 border border-slate-200 dark:border-zinc-800/50')
content = content.replace('bg-zinc-800/60 border-transparent', 'bg-white dark:bg-zinc-800/60 border-slate-200 dark:border-zinc-800')

content = content.replace('text-zinc-400 hover:text-zinc-200', 'text-slate-500 hover:text-slate-900 dark:text-zinc-400 dark:hover:text-zinc-200')
content = content.replace('text-zinc-400', 'text-slate-500 dark:text-zinc-400')

content = re.sub(r'\btext-white\b', 'text-slate-900 dark:text-white', content)

# But we must NOT ruin the text-white inside the ImageMiniPreview because the preview sits on top of images.
# ImageMiniPreview has specific classes: "text-2xl font-black text-slate-900 dark:text-white mb-1 leading-tight"
# I will use a precise replace for text-white outside of previews:
# wait, my regex just replaced all text-white! Let me fix the few preview-specific ones:
content = content.replace('text-2xl font-black text-slate-900 dark:text-white mb-1 leading-tight', 'text-2xl font-black text-white mb-1 leading-tight')
content = content.replace('text-slate-900 dark:text-white text-xs font-bold', 'text-white text-xs font-bold') # For side banner preview texts

content = content.replace('border-zinc-600', 'border-slate-300 dark:border-zinc-600')

content = content.replace("style={{ borderColor: 'rgba(255,200,50,0.1)', background: 'rgba(255,255,255,0.03)' }}", "className=\"border-slate-200 dark:border-zinc-800 bg-slate-50 dark:bg-white/[0.03]\"")
content = content.replace("style={{ borderColor: 'rgba(255,200,50,0.08)' }}", "className=\"border-slate-200 dark:border-zinc-800/50\"")
content = content.replace("style={{ background: accent || 'rgba(255,200,50,0.1)' }}", "className=\"bg-indigo-100 dark:bg-indigo-500/10\"")

content = content.replace("style={{ background: value ? '#F59E0B' : '#3F3F46' }}", "className={value ? 'bg-indigo-500' : 'bg-slate-300 dark:bg-zinc-700'}")

content = content.replace("text-zinc-600 mt-1", "text-slate-500 dark:text-zinc-500 mt-1")
content = content.replace("text-zinc-600 mt-2", "text-slate-500 dark:text-zinc-500 mt-2")
content = content.replace("text-zinc-600 mb-1", "text-slate-500 dark:text-zinc-500 mb-1")
content = content.replace("text-zinc-500", "text-slate-400 dark:text-zinc-500")

# Buttons and inner cards
content = content.replace("background: 'rgba(255,255,255,0.03)'", "''") # Handled by tailwind
content = content.replace("background: 'rgba(255,200,50,0.15)'", "''")
content = content.replace("background: 'rgba(255,255,255,0.02)'", "''")

# Clean up style object injection, we'll convert them to proper tailwind classes
# We will just write a custom replace block for the interactive option buttons.
with open(file_path, "w") as f:
    f.write(content)
print("Updated AdminHeroEditor!")
