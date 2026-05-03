import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { deleteDoc, doc, setDoc } from 'firebase/firestore';
import { db } from '../../firebase';
import { usePosts } from '../../hooks/usePosts';
import { Post } from '../../types';
import { handleFirestoreError, OperationType } from '../../utils/firebaseError';
import { Plus, Edit, Trash2, Search, FileText, Image as ImageIcon, CheckCircle, Clock } from 'lucide-react';
import { toast } from 'sonner';
import { cloudinaryUrl } from '../../utils/cloudinaryUrl';

export default function AdminPostList() {
  const { posts, loading } = usePosts(true);
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');

  const filteredPosts = posts.filter(post => 
    post.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    post.category.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleDelete = async (id: string, title: string) => {
    if (window.confirm(`Bạn có chắc chắn muốn xóa bài viết "${title}"?`)) {
      try {
        await deleteDoc(doc(db, 'posts', id));
        // Delta Sync
        await setDoc(doc(db, 'system', 'version'), {
          postsUpdated: Date.now()
        }, { merge: true });
        toast.success('Đã xóa bài viết');
      } catch (error) {
        handleFirestoreError(error, OperationType.DELETE, `posts/${id}`);
        toast.error('Có lỗi xảy ra khi xóa bài viết');
      }
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-5 h-5 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header & Actions */}
      <div className="flex flex-col sm:flex-row gap-4 items-center justify-between">
        <div className="relative flex-1 w-full sm:max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input 
            type="text" 
            placeholder="Tìm kiếm bài viết..." 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-lg pl-9 pr-4 py-2 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all shadow-sm"
          />
        </div>
        <button 
          onClick={() => navigate('/admin/post/new')} 
          className="w-full sm:w-auto bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg flex items-center justify-center gap-2 text-sm font-medium transition-colors shadow-sm"
        >
          <Plus className="w-4 h-4" /> Viết bài mới
        </button>
      </div>

      {/* Data Table */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 dark:divide-zinc-800 text-sm text-left">
            <thead className="bg-slate-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Bài viết</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Danh mục</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-center">Trạng thái</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-center">Lượt xem</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Ngày tạo</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-right">Tác vụ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-zinc-800">
              {filteredPosts.map(post => (
                <tr key={post.id} className="hover:bg-slate-50 dark:hover:bg-zinc-800/50 transition-colors group">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-12 h-12 rounded-lg bg-slate-100 dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 overflow-hidden shrink-0 flex items-center justify-center">
                        {post.thumbnail ? (
                          <img src={cloudinaryUrl(post.thumbnail, { width: 100, quality: 'auto:low' })} alt={post.title} loading="lazy" decoding="async" className="w-full h-full object-cover" />
                        ) : (
                          <ImageIcon className="w-5 h-5 text-slate-400" />
                        )}
                      </div>
                      <div className="max-w-[300px]">
                        <div className="font-medium text-slate-900 dark:text-slate-100 truncate tooltip-trigger" title={post.title}>
                          {post.title}
                        </div>
                        <div className="text-xs text-slate-500 truncate mt-1">/{post.slug}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="inline-flex items-center px-2 py-1 rounded bg-slate-100 text-slate-700 dark:bg-zinc-800 dark:text-zinc-300 text-xs font-medium">
                      {post.category}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-center">
                    {post.status === 'published' ? (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium border bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/20">
                        <CheckCircle className="w-3.5 h-3.5" /> Đã xuất bản
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium border bg-slate-100 text-slate-600 border-slate-200 dark:bg-zinc-800 dark:text-zinc-400 dark:border-zinc-700">
                        <Clock className="w-3.5 h-3.5" /> Bản nháp
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-center font-medium text-slate-700 dark:text-zinc-300">
                    {post.viewCount || 0}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-500 dark:text-zinc-400 text-sm">
                    {post.createdAt?.toDate().toLocaleDateString('vi-VN')}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm">
                    <div className="flex items-center justify-end gap-2">
                      <button 
                        onClick={() => navigate('/admin/post/' + post.id)} 
                        className="p-1.5 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-500/10 dark:hover:text-indigo-400 rounded-md transition-colors" 
                        title="Sửa"
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                      <button 
                        onClick={() => handleDelete(post.id, post.title)} 
                        className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10 dark:hover:text-red-400 rounded-md transition-colors" 
                        title="Xóa"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filteredPosts.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-500 dark:text-zinc-400">
                    <FileText className="w-10 h-10 mx-auto mb-3 text-slate-300 dark:text-zinc-600" />
                    <p>Không tìm thấy bài viết nào.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
