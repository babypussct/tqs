import React, { useState, useEffect } from 'react';
import { collection, query, where, orderBy, onSnapshot, addDoc, serverTimestamp, deleteDoc, doc, getDocs, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { useAuth } from '../contexts/AuthContext';
import { Review, Order } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { Star, Trash2, User, MessageSquareReply, ShieldCheck } from 'lucide-react';
import { cloudinaryUrl } from '../utils/cloudinaryUrl';

interface ProductReviewsProps {
  productId: string;
  productName?: string;
}

export default function ProductReviews({ productId, productName }: ProductReviewsProps) {
  const { user, isAdmin } = useAuth();
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [hasPurchased, setHasPurchased] = useState(false);
  
  // Form state
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  // Admin reply state
  const [replyingTo, setReplyingTo] = useState<string | null>(null);
  const [replyText, setReplyText] = useState('');
  const [submittingReply, setSubmittingReply] = useState(false);

  useEffect(() => {
    const q = query(
      collection(db, 'reviews'),
      where('productId', '==', productId),
      orderBy('createdAt', 'desc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const reviewsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Review[];
      
      setReviews(reviewsData);
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.LIST, 'reviews');
      setLoading(false);
    });

    return () => unsubscribe();
  }, [productId]);

  useEffect(() => {
    const checkPurchase = async () => {
      if (!user) {
        setHasPurchased(false);
        return;
      }
      
      try {
        const q = query(
          collection(db, 'orders'),
          where('userId', '==', user.uid),
          where('status', '==', 'delivered')
        );
        const snapshot = await getDocs(q);
        const orders = snapshot.docs.map(doc => doc.data() as Order);
        
        const purchased = orders.some(order => 
          order.items.some(item => item.productId === productId)
        );
        
        setHasPurchased(purchased);
      } catch (err) {
        console.error("Error checking purchase status:", err);
      }
    };

    checkPurchase();
  }, [user, productId]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) {
      setError('Vui lòng đăng nhập để đánh giá.');
      return;
    }
    if (!comment.trim()) {
      setError('Vui lòng nhập nội dung đánh giá.');
      return;
    }

    setSubmitting(true);
    setError('');

    try {
      await addDoc(collection(db, 'reviews'), {
        productId,
        userId: user.uid,
        userName: user.displayName || 'Người dùng ẩn danh',
        userPhoto: user.photoURL || '',
        rating,
        comment: comment.trim(),
        createdAt: serverTimestamp()
      });

      // Thông báo Telegram
      fetch('/api/notify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          type: 'NEW_REVIEW',
          payload: {
            productName: productName || productId,
            userName: user.displayName || 'Người dùng ẩn danh',
            rating,
            comment: comment.trim()
          }
        })
      }).catch(() => {});

      setComment('');
      setRating(5);
    } catch (err) {
      handleFirestoreError(err, OperationType.CREATE, 'reviews');
      setError('Có lỗi xảy ra khi gửi đánh giá.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (reviewId: string) => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa đánh giá này?')) return;
    
    try {
      await deleteDoc(doc(db, 'reviews', reviewId));
    } catch (err) {
      handleFirestoreError(err, OperationType.DELETE, `reviews/${reviewId}`);
      alert('Có lỗi xảy ra khi xóa đánh giá.');
    }
  };

  const handleReply = async (reviewId: string) => {
    if (!replyText.trim()) return;
    
    setSubmittingReply(true);
    try {
      await updateDoc(doc(db, 'reviews', reviewId), {
        adminReply: replyText.trim(),
        adminReplyAt: serverTimestamp()
      });
      setReplyingTo(null);
      setReplyText('');
    } catch (err) {
      handleFirestoreError(err, OperationType.UPDATE, `reviews/${reviewId}`);
      alert('Có lỗi xảy ra khi gửi phản hồi.');
    } finally {
      setSubmittingReply(false);
    }
  };

  const averageRating = reviews.length > 0 
    ? (reviews.reduce((acc, r) => acc + r.rating, 0) / reviews.length).toFixed(1)
    : 0;

  const hasReviewed = user ? reviews.some(r => r.userId === user.uid) : false;

  return (
    <div className="mt-16 pt-10 border-t border-gray-200 dark:border-zinc-800">
      <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-8 uppercase tracking-tight">Đánh Giá Sản Phẩm</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
        {/* Rating Summary */}
        <div className="bg-gray-50 dark:bg-zinc-900/50 rounded-2xl p-6 flex flex-col items-center justify-center border border-gray-100 dark:border-zinc-800">
          <div className="text-5xl font-black text-gray-900 dark:text-white mb-2">{averageRating}</div>
          <div className="flex gap-1 text-amber-400 mb-2">
            {[1, 2, 3, 4, 5].map((star) => (
              <Star key={star} className={`w-6 h-6 ${star <= Number(averageRating) ? 'fill-current' : 'text-gray-300 dark:text-zinc-700'}`} />
            ))}
          </div>
          <div className="text-sm text-gray-500 dark:text-zinc-400">{reviews.length} đánh giá</div>
        </div>

        {/* Review Form */}
        <div className="md:col-span-2">
          {user ? (
            hasReviewed ? (
              <div className="bg-green-50 dark:bg-green-500/10 border border-green-200 dark:border-green-500/20 rounded-xl p-6 text-center">
                <p className="text-green-700 dark:text-green-400 font-medium">Bạn đã đánh giá sản phẩm này. Cảm ơn bạn!</p>
              </div>
            ) : hasPurchased ? (
              <form onSubmit={handleSubmit} className="bg-white dark:bg-zinc-900 rounded-2xl p-6 shadow-sm border border-gray-100 dark:border-zinc-800">
                <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Viết đánh giá của bạn</h3>
                
                {error && (
                  <div className="mb-4 p-3 bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-600 dark:text-red-400 rounded-lg text-sm">
                    {error}
                  </div>
                )}

                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Chất lượng sản phẩm</label>
                  <div className="flex gap-2">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button
                        key={star}
                        type="button"
                        onClick={() => setRating(star)}
                        className="focus:outline-none"
                      >
                        <Star className={`w-8 h-8 transition-colors ${star <= rating ? 'fill-amber-400 text-amber-400' : 'text-gray-300 dark:text-zinc-700 hover:text-amber-200'}`} />
                      </button>
                    ))}
                  </div>
                </div>

                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Nội dung đánh giá</label>
                  <textarea
                    value={comment}
                    onChange={(e) => setComment(e.target.value)}
                    rows={3}
                    className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent transition-all resize-none"
                    placeholder="Chia sẻ cảm nhận của bạn về sản phẩm này..."
                    maxLength={1000}
                  />
                </div>

                <button
                  type="submit"
                  disabled={submitting}
                  className="bg-red-600 hover:bg-red-700 text-white font-bold py-2.5 px-6 rounded-xl transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {submitting ? 'Đang gửi...' : 'Gửi Đánh Giá'}
                </button>
              </form>
            ) : (
              <div className="bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/20 rounded-xl p-8 text-center">
                <p className="text-amber-700 dark:text-amber-400 font-medium">Bạn cần mua và nhận sản phẩm này để có thể đánh giá.</p>
              </div>
            )
          ) : (
            <div className="bg-gray-50 dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800 rounded-xl p-8 text-center">
              <p className="text-gray-600 dark:text-zinc-400 mb-4">Vui lòng đăng nhập để có thể đánh giá sản phẩm.</p>
            </div>
          )}
        </div>
      </div>

      {/* Reviews List */}
      <div className="space-y-6">
        {loading ? (
          <div className="text-center py-8 text-gray-500 dark:text-zinc-400">Đang tải đánh giá...</div>
        ) : reviews.length === 0 ? (
          <div className="text-center py-12 bg-gray-50 dark:bg-zinc-900/30 border border-gray-200 dark:border-zinc-800 border-dashed rounded-2xl text-gray-500 dark:text-zinc-400">
            Chưa có đánh giá nào. Hãy là người đầu tiên đánh giá sản phẩm này!
          </div>
        ) : (
          reviews.map((review) => (
            <div key={review.id} className="bg-white dark:bg-zinc-900 rounded-2xl p-6 shadow-sm border border-gray-100 dark:border-zinc-800">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-3">
                  {review.userPhoto ? (
                    <img src={cloudinaryUrl(review.userPhoto, { width: 80, quality: 'auto' })} alt={review.userName} className="w-10 h-10 rounded-full border border-gray-200 dark:border-zinc-700" loading="lazy" decoding="async" referrerPolicy="no-referrer" />
                  ) : (
                    <div className="w-10 h-10 rounded-full bg-gray-200 dark:bg-zinc-800 flex items-center justify-center text-gray-500 dark:text-zinc-400">
                      <User className="w-5 h-5" />
                    </div>
                  )}
                  <div>
                    <h4 className="font-bold text-gray-900 dark:text-white text-sm">{review.userName}</h4>
                    <div className="flex items-center gap-2 mt-1">
                      <div className="flex text-amber-400">
                        {[1, 2, 3, 4, 5].map((star) => (
                          <Star key={star} className={`w-3.5 h-3.5 ${star <= review.rating ? 'fill-current' : 'text-gray-300 dark:text-zinc-700'}`} />
                        ))}
                      </div>
                      <span className="text-xs text-gray-500 dark:text-zinc-400">
                        {review.createdAt?.toDate ? new Date(review.createdAt.toDate()).toLocaleDateString('vi-VN') : 'Mới đây'}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center gap-2">
                  {isAdmin && !review.adminReply && (
                    <button
                      onClick={() => setReplyingTo(replyingTo === review.id ? null : review.id)}
                      className="p-2 text-gray-400 hover:text-blue-500 hover:bg-blue-50 dark:hover:bg-blue-500/10 rounded-lg transition-colors"
                      title="Phản hồi"
                    >
                      <MessageSquareReply className="w-4 h-4" />
                    </button>
                  )}
                  {(isAdmin || (user && user.uid === review.userId)) && (
                    <button
                      onClick={() => handleDelete(review.id)}
                      className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors"
                      title="Xóa đánh giá"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  )}
                </div>
              </div>
              <p className="text-gray-700 dark:text-zinc-300 text-sm leading-relaxed whitespace-pre-wrap">
                {review.comment}
              </p>

              {/* Admin Reply Display */}
              {review.adminReply && (
                <div className="mt-4 ml-4 md:ml-12 p-4 bg-gray-50 dark:bg-zinc-800/50 rounded-xl border-l-2 border-red-500">
                  <div className="flex items-center gap-2 mb-2">
                    <ShieldCheck className="w-4 h-4 text-red-500" />
                    <span className="font-bold text-sm text-gray-900 dark:text-white">Phản hồi từ TQS Store</span>
                    {review.adminReplyAt && (
                      <span className="text-xs text-gray-500 dark:text-zinc-400 ml-auto">
                        {review.adminReplyAt.toDate ? new Date(review.adminReplyAt.toDate()).toLocaleDateString('vi-VN') : ''}
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-700 dark:text-zinc-300 whitespace-pre-wrap">
                    {review.adminReply}
                  </p>
                </div>
              )}

              {/* Admin Reply Form */}
              {isAdmin && replyingTo === review.id && !review.adminReply && (
                <div className="mt-4 ml-4 md:ml-12">
                  <textarea
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    rows={2}
                    className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-xl px-4 py-3 text-sm text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent transition-all resize-none mb-2"
                    placeholder="Nhập phản hồi của bạn..."
                  />
                  <div className="flex justify-end gap-2">
                    <button
                      onClick={() => {
                        setReplyingTo(null);
                        setReplyText('');
                      }}
                      className="px-4 py-2 text-sm text-gray-600 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-800 rounded-lg transition-colors"
                    >
                      Hủy
                    </button>
                    <button
                      onClick={() => handleReply(review.id)}
                      disabled={submittingReply || !replyText.trim()}
                      className="px-4 py-2 text-sm bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg transition-colors disabled:opacity-50"
                    >
                      {submittingReply ? 'Đang gửi...' : 'Gửi phản hồi'}
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
