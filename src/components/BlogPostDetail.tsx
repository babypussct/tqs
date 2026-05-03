import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { collection, query, where, getDocs, doc, updateDoc, increment } from 'firebase/firestore';
import { db } from '../firebase';
import { Post } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { Calendar, Eye, User, ArrowLeft, Share2 } from 'lucide-react';
import { toast } from 'sonner';
import { cloudinaryUrl } from '../utils/cloudinaryUrl';

export default function BlogPostDetail() {
  const { slug } = useParams();
  const navigate = useNavigate();
  const [post, setPost] = useState<Post | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchPost() {
      if (!slug) return;
      try {
        const q = query(collection(db, 'posts'), where('slug', '==', slug));
        const querySnapshot = await getDocs(q);
        
        if (!querySnapshot.empty) {
          const postDoc = querySnapshot.docs[0];
          const postData = { id: postDoc.id, ...postDoc.data() } as Post;
          
          // Only show published posts to public
          if (postData.status === 'published') {
            setPost(postData);
            
            // Increment view count (fire and forget)
            updateDoc(doc(db, 'posts', postDoc.id), {
              viewCount: increment(1)
            }).catch(console.error);
          } else {
            toast.error('Bài viết này hiện chưa được xuất bản.');
            navigate('/blog');
          }
        } else {
          toast.error('Không tìm thấy bài viết.');
          navigate('/blog');
        }
      } catch (error) {
        handleFirestoreError(error, OperationType.GET, 'posts');
      } finally {
        setLoading(false);
      }
    }
    
    fetchPost();
  }, [slug, navigate]);

  const handleShare = () => {
    if (navigator.share) {
      navigator.share({
        title: post?.title,
        text: post?.excerpt,
        url: window.location.href,
      }).catch(console.error);
    } else {
      navigator.clipboard.writeText(window.location.href);
      toast.success('Đã sao chép đường dẫn bài viết!');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen pt-20">
        <div className="w-8 h-8 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!post) return null;

  return (
    <article className="min-h-screen bg-slate-50 dark:bg-zinc-950 text-slate-900 dark:text-zinc-50 pt-20 pb-24">
      {/* Article Header & Cover */}
      <div className="w-full bg-white dark:bg-zinc-900 border-b border-slate-200 dark:border-zinc-800">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <button 
            onClick={() => navigate('/blog')}
            className="inline-flex items-center gap-2 text-sm text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 font-medium mb-8 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" /> Quay lại Tin tức
          </button>
          
          <div className="mb-4 flex items-center gap-2">
            <span className="bg-indigo-50 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-400 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider">
              {post.category}
            </span>
          </div>
          
          <h1 className="text-3xl sm:text-4xl md:text-5xl font-extrabold text-slate-900 dark:text-white mb-6 leading-tight">
            {post.title}
          </h1>
          
          <div className="flex flex-wrap items-center gap-y-3 gap-x-6 text-sm text-slate-500 dark:text-zinc-400 font-medium">
            <div className="flex items-center gap-2">
              <Calendar className="w-4 h-4" />
              {post.createdAt?.toDate().toLocaleDateString('vi-VN')}
            </div>
            <div className="flex items-center gap-2">
              <Eye className="w-4 h-4" />
              {post.viewCount || 0} lượt xem
            </div>
            <div className="flex items-center gap-2">
              <User className="w-4 h-4" />
              {post.authorName || 'Admin'}
            </div>
          </div>
        </div>
      </div>

      {post.thumbnail && (
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 relative z-10">
          <div className="aspect-video w-full rounded-2xl overflow-hidden shadow-2xl border border-slate-200/50 dark:border-zinc-700/50 bg-slate-100 dark:bg-zinc-800">
            <img 
              src={cloudinaryUrl(post.thumbnail, { width: 1200, quality: 'auto:good' })} 
              alt={post.title} 
              // @ts-ignore
              fetchpriority="high"
              decoding="async"
              className="w-full h-full object-cover"
              referrerPolicy="no-referrer"
            />
          </div>
        </div>
      )}

      {/* Article Content */}
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        {post.excerpt && (
          <div className="text-lg text-slate-600 dark:text-zinc-400 font-medium lead-relaxed mb-10 border-l-4 border-indigo-500 pl-6 italic">
            {post.excerpt}
          </div>
        )}
        
        {/* Rich Text Viewer using Tailwind Typography */}
        <div 
          className="prose prose-slate dark:prose-invert prose-lg max-w-none 
                    prose-headings:font-bold prose-h2:text-3xl prose-h3:text-2xl 
                    prose-a:text-indigo-600 dark:prose-a:text-indigo-400 
                    prose-img:rounded-xl prose-img:shadow-md
                    prose-table:w-full prose-table:border-collapse prose-table:my-8
                    prose-th:border prose-th:border-slate-200 dark:prose-th:border-zinc-700 prose-th:p-3 prose-th:bg-slate-50 dark:prose-th:bg-zinc-800/50 
                    prose-td:border prose-td:border-slate-200 dark:prose-td:border-zinc-700 prose-td:p-3
                    prose-iframe:w-full prose-iframe:aspect-video prose-iframe:rounded-xl prose-iframe:shadow-md"
          dangerouslySetInnerHTML={{ __html: post.content }}
        />
        
        {/* Footer Actions */}
        <div className="mt-16 pt-8 border-t border-slate-200 dark:border-zinc-800 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 flex-wrap">
            {post.tags?.map(tag => (
              <span key={tag} className="bg-slate-100 dark:bg-zinc-800 text-slate-600 dark:text-zinc-400 px-3 py-1 rounded-full text-xs font-medium">
                #{tag}
              </span>
            ))}
          </div>
          
          <button 
            onClick={handleShare}
            className="flex items-center gap-2 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700 px-4 py-2 rounded-lg font-medium text-sm transition-colors"
          >
            <Share2 className="w-4 h-4" />
            Chia sẻ bài viết
          </button>
        </div>
      </div>
    </article>
  );
}
