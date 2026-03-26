import { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, addDoc, updateDoc, deleteDoc, doc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../firebase';
import { DiscountCode } from '../../types';
import { Plus, Edit2, Trash2, X, Check, AlertCircle } from 'lucide-react';
import { handleFirestoreError } from '../../utils/firebaseError';

export default function AdminDiscountCodes() {
  const [codes, setCodes] = useState<DiscountCode[]>([]);
  const [loading, setLoading] = useState(true);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingCode, setEditingCode] = useState<DiscountCode | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [code, setCode] = useState('');
  const [discountType, setDiscountType] = useState<'percentage' | 'fixed'>('percentage');
  const [discountValue, setDiscountValue] = useState('');
  const [minOrderValue, setMinOrderValue] = useState('');
  const [maxDiscount, setMaxDiscount] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [usageLimit, setUsageLimit] = useState('');
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    const q = query(collection(db, 'discountCodes'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const codesData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as DiscountCode[];
      setCodes(codesData);
      setLoading(false);
    }, (err) => {
      console.error("Error fetching discount codes:", err);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const resetForm = () => {
    setCode('');
    setDiscountType('percentage');
    setDiscountValue('');
    setMinOrderValue('');
    setMaxDiscount('');
    setStartDate('');
    setEndDate('');
    setUsageLimit('');
    setIsActive(true);
    setEditingCode(null);
    setIsFormOpen(false);
    setError(null);
  };

  const handleEdit = (codeToEdit: DiscountCode) => {
    setEditingCode(codeToEdit);
    setCode(codeToEdit.code);
    setDiscountType(codeToEdit.discountType);
    setDiscountValue(codeToEdit.discountValue.toString());
    setMinOrderValue(codeToEdit.minOrderValue?.toString() || '');
    setMaxDiscount(codeToEdit.maxDiscount?.toString() || '');
    
    // Format dates for input type="datetime-local"
    const start = codeToEdit.startDate?.toDate ? codeToEdit.startDate.toDate() : new Date();
    const end = codeToEdit.endDate?.toDate ? codeToEdit.endDate.toDate() : new Date();
    
    // Adjust for timezone offset to display correctly in local time input
    const startStr = new Date(start.getTime() - start.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    const endStr = new Date(end.getTime() - end.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    
    setStartDate(startStr);
    setEndDate(endStr);
    
    setUsageLimit(codeToEdit.usageLimit?.toString() || '');
    setIsActive(codeToEdit.isActive);
    setIsFormOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    try {
      if (!code || !discountValue || !startDate || !endDate) {
        throw new Error('Vui lòng điền đầy đủ các trường bắt buộc');
      }

      const start = new Date(startDate);
      const end = new Date(endDate);

      if (start >= end) {
        throw new Error('Ngày kết thúc phải sau ngày bắt đầu');
      }

      const codeData = {
        code: code.toUpperCase(),
        discountType,
        discountValue: Number(discountValue),
        minOrderValue: minOrderValue ? Number(minOrderValue) : null,
        maxDiscount: maxDiscount ? Number(maxDiscount) : null,
        startDate: start,
        endDate: end,
        usageLimit: usageLimit ? Number(usageLimit) : null,
        isActive,
        updatedAt: serverTimestamp()
      };

      // Remove null values
      Object.keys(codeData).forEach(key => {
        if ((codeData as any)[key] === null) {
          delete (codeData as any)[key];
        }
      });

      if (editingCode) {
        await updateDoc(doc(db, 'discountCodes', editingCode.id), codeData);
      } else {
        // Check if code already exists
        const existingCode = codes.find(c => c.code === code.toUpperCase());
        if (existingCode) {
          throw new Error('Mã giảm giá này đã tồn tại');
        }

        await addDoc(collection(db, 'discountCodes'), {
          ...codeData,
          usedCount: 0,
          createdAt: serverTimestamp()
        });
      }

      resetForm();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Có lỗi xảy ra');
    }
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa mã giảm giá này?')) {
      try {
        await deleteDoc(doc(db, 'discountCodes', id));
      } catch (err) {
        console.error("Error deleting discount code:", err);
        alert('Có lỗi xảy ra khi xóa mã giảm giá');
      }
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value);
  };

  if (loading) {
    return <div className="p-8 text-center text-gray-500">Đang tải...</div>;
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Quản lý Mã Giảm Giá</h2>
        <button
          onClick={() => {
            resetForm();
            setIsFormOpen(true);
          }}
          className="flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg transition-colors"
        >
          <Plus className="w-5 h-5" />
          Thêm Mã Mới
        </button>
      </div>

      {isFormOpen && (
        <div className="mb-8 bg-white dark:bg-zinc-900 p-6 rounded-xl border border-gray-200 dark:border-zinc-800 shadow-sm">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">
              {editingCode ? 'Sửa Mã Giảm Giá' : 'Thêm Mã Giảm Giá Mới'}
            </h3>
            <button onClick={resetForm} className="text-gray-500 hover:text-gray-700 dark:text-zinc-400 dark:hover:text-zinc-300">
              <X className="w-5 h-5" />
            </button>
          </div>

          {error && (
            <div className="mb-4 p-3 bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 rounded-lg flex items-center gap-2 text-red-600 dark:text-red-400 text-sm">
              <AlertCircle className="w-4 h-4" />
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1">Mã giảm giá *</label>
                <input
                  type="text"
                  value={code}
                  onChange={(e) => setCode(e.target.value.toUpperCase())}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-lg px-4 py-2 text-gray-900 dark:text-white uppercase"
                  required
                  disabled={!!editingCode}
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1">Loại giảm giá *</label>
                <select
                  value={discountType}
                  onChange={(e) => setDiscountType(e.target.value as 'percentage' | 'fixed')}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-lg px-4 py-2 text-gray-900 dark:text-white"
                >
                  <option value="percentage">Phần trăm (%)</option>
                  <option value="fixed">Số tiền cố định (VNĐ)</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1">
                  Giá trị giảm * {discountType === 'percentage' ? '(%)' : '(VNĐ)'}
                </label>
                <input
                  type="number"
                  value={discountValue}
                  onChange={(e) => setDiscountValue(e.target.value)}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-lg px-4 py-2 text-gray-900 dark:text-white"
                  required
                  min="1"
                  max={discountType === 'percentage' ? "100" : undefined}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1">Giá trị đơn tối thiểu (VNĐ)</label>
                <input
                  type="number"
                  value={minOrderValue}
                  onChange={(e) => setMinOrderValue(e.target.value)}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-lg px-4 py-2 text-gray-900 dark:text-white"
                  min="0"
                />
              </div>

              {discountType === 'percentage' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1">Giảm tối đa (VNĐ)</label>
                  <input
                    type="number"
                    value={maxDiscount}
                    onChange={(e) => setMaxDiscount(e.target.value)}
                    className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-lg px-4 py-2 text-gray-900 dark:text-white"
                    min="0"
                  />
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1">Giới hạn số lần sử dụng</label>
                <input
                  type="number"
                  value={usageLimit}
                  onChange={(e) => setUsageLimit(e.target.value)}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-lg px-4 py-2 text-gray-900 dark:text-white"
                  min="1"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1">Ngày bắt đầu *</label>
                <input
                  type="datetime-local"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-lg px-4 py-2 text-gray-900 dark:text-white"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1">Ngày kết thúc *</label>
                <input
                  type="datetime-local"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-lg px-4 py-2 text-gray-900 dark:text-white"
                  required
                />
              </div>
            </div>

            <div className="flex items-center mt-4">
              <input
                type="checkbox"
                id="isActive"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
                className="w-4 h-4 text-red-600 border-gray-300 rounded focus:ring-red-500"
              />
              <label htmlFor="isActive" className="ml-2 text-sm font-medium text-gray-700 dark:text-zinc-300">
                Kích hoạt mã giảm giá này
              </label>
            </div>

            <div className="flex justify-end gap-3 mt-6">
              <button
                type="button"
                onClick={resetForm}
                className="px-4 py-2 text-gray-700 dark:text-zinc-300 hover:bg-gray-100 dark:hover:bg-zinc-800 rounded-lg transition-colors"
              >
                Hủy
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg transition-colors"
              >
                {editingCode ? 'Cập nhật' : 'Thêm mới'}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="bg-white dark:bg-zinc-900 rounded-xl border border-gray-200 dark:border-zinc-800 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-50 dark:bg-zinc-950 border-b border-gray-200 dark:border-zinc-800 text-gray-600 dark:text-zinc-400">
              <tr>
                <th className="px-6 py-4 font-medium">Mã</th>
                <th className="px-6 py-4 font-medium">Giảm giá</th>
                <th className="px-6 py-4 font-medium">Điều kiện</th>
                <th className="px-6 py-4 font-medium">Thời gian</th>
                <th className="px-6 py-4 font-medium">Đã dùng</th>
                <th className="px-6 py-4 font-medium">Trạng thái</th>
                <th className="px-6 py-4 font-medium text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-zinc-800">
              {codes.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-8 text-center text-gray-500 dark:text-zinc-400">
                    Chưa có mã giảm giá nào
                  </td>
                </tr>
              ) : (
                codes.map((code) => {
                  const isExpired = code.endDate?.toDate && code.endDate.toDate() < new Date();
                  const isLimitReached = code.usageLimit && code.usedCount >= code.usageLimit;
                  const isActuallyActive = code.isActive && !isExpired && !isLimitReached;

                  return (
                    <tr key={code.id} className="hover:bg-gray-50 dark:hover:bg-zinc-800/50">
                      <td className="px-6 py-4">
                        <span className="font-mono font-bold text-gray-900 dark:text-white bg-gray-100 dark:bg-zinc-800 px-2 py-1 rounded">
                          {code.code}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-gray-700 dark:text-zinc-300">
                        {code.discountType === 'percentage' 
                          ? `${code.discountValue}%` 
                          : formatCurrency(code.discountValue)}
                        {code.maxDiscount && (
                          <div className="text-xs text-gray-500 mt-1">
                            Tối đa: {formatCurrency(code.maxDiscount)}
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 text-gray-700 dark:text-zinc-300">
                        {code.minOrderValue ? `Đơn từ ${formatCurrency(code.minOrderValue)}` : 'Mọi đơn hàng'}
                      </td>
                      <td className="px-6 py-4 text-gray-700 dark:text-zinc-300 text-xs">
                        <div>Từ: {code.startDate?.toDate ? new Date(code.startDate.toDate()).toLocaleString('vi-VN') : ''}</div>
                        <div>Đến: {code.endDate?.toDate ? new Date(code.endDate.toDate()).toLocaleString('vi-VN') : ''}</div>
                      </td>
                      <td className="px-6 py-4 text-gray-700 dark:text-zinc-300">
                        {code.usedCount} {code.usageLimit ? `/ ${code.usageLimit}` : ''}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          isActuallyActive
                            ? 'bg-green-100 text-green-800 dark:bg-green-500/10 dark:text-green-400'
                            : 'bg-red-100 text-red-800 dark:bg-red-500/10 dark:text-red-400'
                        }`}>
                          {isActuallyActive ? 'Đang hoạt động' : (isExpired ? 'Đã hết hạn' : (isLimitReached ? 'Đã hết lượt' : 'Đã tắt'))}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => handleEdit(code)}
                            className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-500/10 rounded-lg transition-colors"
                            title="Sửa"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(code.id)}
                            className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors"
                            title="Xóa"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
