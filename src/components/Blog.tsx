import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { usePosts } from '../hooks/usePosts';
import { Clock, Eye, ChevronRight, FileText, Calendar } from 'lucide-react';
import { motion } from 'motion/react';

export default function Blog() {
  const { posts, loading } = usePosts();
  const navigate = useNavigate();
  const [activeCategory, setActiveCategory] = useState<string>('Tất cả');

  const publishedPosts = posts.filter(post => post.status === 'published');
  
  // Extract unique categories
  const categories = ['Tất cả', ...Array.from(new Set(publishedPosts.map(p => p.category)))];

  const filteredPosts = activeCategory === 'Tất cả' 
    ? publishedPosts 
    : publishedPosts.filter(p => p.category === activeCategory);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="w-8 h-8 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-zinc-950 text-slate-900 dark:text-zinc-50 pt-24 pb-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Header & Categories */}
        <div className="mb-12 text-center max-w-3xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h1 className="text-4xl sm:text-5xl font-extrabold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-indigo-500 to-purple-600 dark:from-indigo-400 dark:to-purple-500">
              Tin tức & Sự kiện
            </h1>
            <p className="text-lg text-slate-600 dark:text-zinc-400">
              Cập nhật thông tin mới nhất về luật chơi, các sự kiện sắp diễn ra và những bài chia sẻ đầy cảm hứng.
            </p>
          </motion.div>

          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="flex flex-wrap items-center justify-center gap-2 mt-8"
          >
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setActiveCategory(cat)}
                className={`px-5 py-2 rounded-full text-sm font-medium transition-all ${
                  activeCategory === cat
                    ? 'bg-indigo-600 text-white shadow-md shadow-indigo-500/20'
                    : 'bg-white dark:bg-zinc-900 text-slate-600 dark:text-zinc-400 hover:bg-indigo-50 dark:hover:bg-zinc-800 border border-slate-200 dark:border-zinc-800'
                }`}
              >
                {cat}
              </button>
            ))}
          </motion.div>
        </div>

        {/* Blog Grid */}
        {filteredPosts.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {filteredPosts.map((post, index) => (
              <motion.article 
                key={post.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                onClick={() => navigate(`/blog/${post.slug}`)}
                className="group cursor-pointer bg-white dark:bg-zinc-900 rounded-2xl overflow-hidden border border-slate-200 dark:border-zinc-800 shadow-sm hover:shadow-xl transition-all duration-300 flex flex-col"
              >
                {/* Thumbnail Container */}
                <div className="relative h-56 w-full overflow-hidden bg-slate-100 dark:bg-zinc-800">
                  {post.thumbnail ? (
                    <img 
                      src={post.thumbnail} 
                      alt={post.title} 
                      className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                      referrerPolicy="no-referrer"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-slate-300 dark:text-zinc-600">
                      <FileText className="w-12 h-12" />
                    </div>
                  )}
                  {/* Category Badge overlaying the image */}
                  <div className="absolute top-4 left-4 bg-white/90 dark:bg-zinc-900/90 backdrop-blur-sm px-3 py-1 rounded-full text-xs font-bold text-indigo-600 dark:text-indigo-400 capitalize">
                    {post.category}
                  </div>
                </div>

                {/* Content */}
                <div className="p-6 flex flex-col flex-1">
                  <div className="flex items-center gap-4 text-xs text-slate-500 dark:text-zinc-400 mb-3">
                    <span className="flex items-center gap-1.5"><Calendar className="w-3.5 h-3.5" /> {post.createdAt?.toDate().toLocaleDateString('vi-VN')}</span>
                    <span className="flex items-center gap-1.5"><Eye className="w-3.5 h-3.5" /> {post.viewCount || 0} lượt xem</span>
                  </div>
                  
                  <h3 className="text-xl font-bold mb-2 text-slate-900 dark:text-white line-clamp-2 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
                    {post.title}
                  </h3>
                  
                  {post.excerpt && (
                    <p className="text-sm text-slate-600 dark:text-zinc-400 line-clamp-3 mb-4 flex-1">
                      {post.excerpt}
                    </p>
                  )}
                  
                  <div className="mt-auto pt-4 border-t border-slate-100 dark:border-zinc-800 flex items-center text-indigo-600 dark:text-indigo-400 font-medium text-sm group-hover:translate-x-1 transition-transform">
                    Đọc tiếp <ChevronRight className="w-4 h-4 ml-1" />
                  </div>
                </div>
              </motion.article>
            ))}
          </div>
        ) : (
          <div className="text-center py-20 bg-white dark:bg-zinc-900 rounded-3xl border border-slate-200 dark:border-zinc-800 border-dashed">
            <FileText className="w-16 h-16 mx-auto mb-4 text-slate-300 dark:text-zinc-700" />
            <h3 className="text-xl font-bold text-slate-700 dark:text-zinc-300 mb-2">Chưa có bài viết nào</h3>
            <p className="text-slate-500 dark:text-zinc-500 max-w-sm mx-auto">
              Hiện tại không có bài viết nào trong danh mục này. Vui lòng quay lại sau nhé.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
