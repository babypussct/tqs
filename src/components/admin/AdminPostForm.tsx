import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { doc, getDoc, setDoc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { db } from '../../firebase';
import { Post } from '../../types';
import { handleFirestoreError, OperationType } from '../../utils/firebaseError';
import { ArrowLeft, Save, Image as ImageIcon } from 'lucide-react';
import { toast } from 'sonner';
import { RichTextEditor } from '../ui/RichTextEditor';
import { ImageUploader } from '../ui/ImageUploader';
import { useAuth } from '../../contexts/AuthContext';

export default function AdminPostForm() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  const isEditing = Boolean(id);

  const [loading, setLoading] = useState(isEditing);
  const [saving, setSaving] = useState(false);
  const [post, setPost] = useState<Partial<Post>>({
    title: '',
    slug: '',
    excerpt: '',
    content: '',
    thumbnail: '',
    category: 'Thông báo',
    tags: [],
    status: 'draft',
    viewCount: 0
  });

  useEffect(() => {
    async function fetchPost() {
      if (!id) return;
      try {
        const docRef = doc(db, 'posts', id);
        const docSnap = await getDoc(docRef);
        if (docSnap.exists()) {
          setPost(docSnap.data() as Post);
        } else {
          toast.error('Không tìm thấy bài viết');
          navigate('/admin');
        }
      } catch (error) {
        handleFirestoreError(error, OperationType.GET, `posts/${id}`);
      } finally {
        setLoading(false);
      }
    }
    fetchPost();
  }, [id, navigate]);

  const generateSlug = (text: string) => {
    return text
      .toLowerCase()
      .normalize('NFD') // decomposed forms
      .replace(/[\u0300-\u036f]/g, '') // remove diacritics
      .replace(/đ/g, 'd').replace(/Đ/g, 'D')
      .replace(/[^a-z0-9 ]/g, '') // remove special chars
      .trim()
      .replace(/\s+/g, '-'); // replace spaces with hyphens
  };

  const handleTitleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newTitle = e.target.value;
    setPost(prev => ({
      ...prev,
      title: newTitle,
      slug: prev.slug === generateSlug(prev.title || '') || !prev.slug ? generateSlug(newTitle) : prev.slug
    }));
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!post.title || !post.slug || !post.content) {
      toast.error('Vui lòng nhập đầy đủ tiêu đề, slug và nội dung');
      return;
    }

    setSaving(true);
    try {
      const postId = id || `post_${Date.now()}`;
      const postRef = doc(db, 'posts', postId);

      const postData = {
        ...post,
        id: postId,
        updatedAt: serverTimestamp(),
        authorId: post.authorId || adminUser?.id || 'admin',
        authorName: post.authorName || adminUser?.name || 'Administrator',
      };

      if (!isEditing) {
        postData.createdAt = serverTimestamp();
      }

      await setDoc(postRef, postData, { merge: true });
      toast.success(isEditing ? 'Đã cập nhật bài viết' : 'Đã tạo bài viết mới');
      // Always go back to admin dashboard where the posts tab should be active
      // In the future you might save the tab state, but here we just navigate to /admin
      navigate('/admin');
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, 'posts');
      toast.error('Lỗi khi lưu bài viết');
    } finally {
      setSaving(false);
    }
  };

  if (loading) return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="w-5 h-5 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
    </div>
  );

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-zinc-950 text-slate-900 dark:text-zinc-50 pb-20">
      <div className="bg-white dark:bg-zinc-900 border-b border-slate-200 dark:border-zinc-800 sticky top-0 z-20">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <button 
                onClick={() => navigate('/admin')}
                className="p-2 -ml-2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 rounded-lg transition-colors"
              >
                <ArrowLeft className="w-5 h-5" />
              </button>
              <h1 className="text-lg font-semibold">
                {isEditing ? 'Chỉnh sửa bài viết' : 'Thêm bài viết mới'}
              </h1>
            </div>
            <button
              onClick={handleSave}
              disabled={saving}
              className="bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-4 py-2 rounded-lg flex items-center gap-2 text-sm font-medium transition-colors shadow-sm"
            >
              <Save className="w-4 h-4" />
              {saving ? 'Đang lưu...' : 'Lưu bài viết'}
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <form onSubmit={handleSave} className="space-y-6">
          {/* Cover Image */}
          <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl p-6 shadow-sm">
            <h2 className="text-sm font-semibold mb-4 flex items-center gap-2">
              <ImageIcon className="w-4 h-4 text-indigo-500" /> Ảnh bìa (Thumbnail)
            </h2>
            <ImageUploader
              value={post.thumbnail || ''}
              onChange={(url) => setPost(prev => ({ ...prev, thumbnail: url }))}
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="md:col-span-2 space-y-6">
              {/* Basic Info */}
              <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl p-6 shadow-sm space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1">Tiêu đề bài viết *</label>
                  <input
                    type="text"
                    required
                    value={post.title}
                    onChange={handleTitleChange}
                    className="w-full bg-slate-50 dark:bg-zinc-950 border border-slate-200 dark:border-zinc-700 rounded-lg px-4 py-2 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all"
                    placeholder="VD: Cập nhật luật chơi tháng 4..."
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1">Đường dẫn (Slug) *</label>
                  <input
                    type="text"
                    required
                    value={post.slug}
                    onChange={(e) => setPost(prev => ({ ...prev, slug: e.target.value }))}
                    className="w-full bg-slate-50 dark:bg-zinc-950 border border-slate-200 dark:border-zinc-700 rounded-lg px-4 py-2 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all font-mono text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1">Đoạn trích dẫn (Excerpt)</label>
                  <textarea
                    rows={3}
                    value={post.excerpt}
                    onChange={(e) => setPost(prev => ({ ...prev, excerpt: e.target.value }))}
                    className="w-full bg-slate-50 dark:bg-zinc-950 border border-slate-200 dark:border-zinc-700 rounded-lg px-4 py-2 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all resize-none"
                    placeholder="Mô tả ngắn gọn về bài viết để hiển thị ngoài danh sách..."
                  />
                </div>
              </div>

              {/* Rich Text Editor */}
              <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl p-6 shadow-sm">
                <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-4">Nội dung chi tiết *</label>
                <div className="min-h-[400px]">
                  <RichTextEditor
                    value={post.content || ''}
                    onChange={(html) => setPost(prev => ({ ...prev, content: html }))}
                    placeholder="Viết nội dung bài viết vào đây..."
                  />
                </div>
              </div>
            </div>

            <div className="space-y-6">
              {/* Properties */}
              <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl p-6 shadow-sm space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1">Trạng thái</label>
                  <select
                    value={post.status}
                    onChange={(e) => setPost(prev => ({ ...prev, status: e.target.value as 'draft' | 'published' }))}
                    className="w-full bg-slate-50 dark:bg-zinc-950 border border-slate-200 dark:border-zinc-700 rounded-lg px-4 py-2 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all"
                  >
                    <option value="draft">Bản nháp</option>
                    <option value="published">Đã xuất bản</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1">Danh mục</label>
                  <select
                    value={post.category}
                    onChange={(e) => setPost(prev => ({ ...prev, category: e.target.value }))}
                    className="w-full bg-slate-50 dark:bg-zinc-950 border border-slate-200 dark:border-zinc-700 rounded-lg px-4 py-2 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all"
                  >
                    <option value="Luật chơi">Luật chơi</option>
                    <option value="Thông báo">Thông báo</option>
                    <option value="Kiến thức">Kiến thức</option>
                    <option value="Sự kiện">Sự kiện</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1">Lượt xem</label>
                  <input
                    type="number"
                    value={post.viewCount || 0}
                    disabled
                    className="w-full bg-slate-100 dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 rounded-lg px-4 py-2 text-slate-500 dark:text-zinc-400 cursor-not-allowed"
                  />
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
