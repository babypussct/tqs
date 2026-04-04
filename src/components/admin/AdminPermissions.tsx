import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, doc, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../firebase';
import { AdminUser, AdminPermissions as IAdminPermissions } from '../../types';
import { handleFirestoreError, OperationType } from '../../utils/firebaseError';
import { Shield, Plus, Trash2, User, Mail, ShieldAlert } from 'lucide-react';
import { toast } from 'sonner';
import { useAuth } from '../../contexts/AuthContext';

const DEFAULT_PERMISSIONS: IAdminPermissions = {
  manageProducts: false,
  manageOrders: false,
  manageHomepage: false,
  manageDiscounts: false,
  manageSettings: false,
  manageRoles: false,
};

export default function AdminPermissions() {
  const { adminUser: currentUser } = useAuth();
  const [admins, setAdmins] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newAdminEmail, setNewAdminEmail] = useState('');

  useEffect(() => {
    const q = collection(db, 'adminUsers');
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const adminList: AdminUser[] = [];
      snapshot.forEach((doc) => {
        adminList.push({ id: doc.id, ...doc.data() } as AdminUser);
      });
      setAdmins(adminList);
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.GET, 'adminUsers');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleTogglePermission = async (adminId: string, permission: keyof IAdminPermissions, currentValue: boolean) => {
    // Only super admin or users with manageRoles can do this
    if (!currentUser?.isSuperAdmin && !currentUser?.permissions.manageRoles) {
      toast.error('Bạn không có quyền thay đổi phân quyền');
      return;
    }

    try {
      const adminRef = doc(db, 'adminUsers', adminId);
      const targetAdmin = admins.find(a => a.id === adminId);
      if (!targetAdmin) return;
      
      const updatedPermissions = {
        ...targetAdmin.permissions,
        [permission]: !currentValue
      };

      await setDoc(adminRef, { permissions: updatedPermissions }, { merge: true });
      toast.success('Đã cập nhật quyền');
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `adminUsers/${adminId}`);
      toast.error('Lỗi khi cập nhật quyền');
    }
  };

  const handleAddAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newAdminEmail.trim()) {
      toast.error('Vui lòng nhập email');
      return;
    }

    try {
      const email = newAdminEmail.trim().toLowerCase();
      // Use email as document ID for easy lookup during login
      const adminRef = doc(db, 'adminUsers', email);
      
      await setDoc(adminRef, {
        email,
        name: email.split('@')[0],
        permissions: DEFAULT_PERMISSIONS,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
      
      toast.success('Đã thêm Quản trị viên mới');
      setNewAdminEmail('');
      setShowAddModal(false);
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'adminUsers');
      toast.error('Lỗi khi thêm quản trị viên');
    }
  };

  const handleDeleteAdmin = async (adminId: string) => {
    if (adminId === 'oneloveonepeopleforever@gmail.com') {
      toast.error('Không thể xóa Super Admin');
      return;
    }
    
    if (window.confirm('Bạn có chắc chắn muốn xóa quyền của người dùng này?')) {
      try {
        await deleteDoc(doc(db, 'adminUsers', adminId));
        toast.success('Đã xóa Quản trị viên');
      } catch (error) {
        handleFirestoreError(error, OperationType.DELETE, `adminUsers/${adminId}`);
        toast.error('Lỗi khi xóa quản trị viên');
      }
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[40vh]">
        <div className="w-5 h-5 border-2 border-red-600 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  // Include SuperAdmin artificially if not in DB to make sure it's visible
  const displayAdmins = [...admins];
  if (!displayAdmins.some(a => a.email === 'oneloveonepeopleforever@gmail.com')) {
    displayAdmins.unshift({
      id: 'oneloveonepeopleforever@gmail.com',
      email: 'oneloveonepeopleforever@gmail.com',
      name: 'Super Admin',
      permissions: {
        manageProducts: true,
        manageOrders: true,
        manageHomepage: true,
        manageDiscounts: true,
        manageSettings: true,
        manageRoles: true
      },
      createdAt: new Date(),
      updatedAt: new Date(),
      isSuperAdmin: true,
    });
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <Shield className="w-6 h-6 text-indigo-500" />
            Phân Quyền Hệ Thống
          </h2>
          <p className="text-sm text-gray-500 dark:text-zinc-400 mt-1">
            Quản lý danh sách Quản trị viên và phân quyền truy cập các module.
          </p>
        </div>
        {(currentUser?.isSuperAdmin || currentUser?.permissions.manageRoles) && (
          <button
            onClick={() => setShowAddModal(true)}
            className="w-full sm:w-auto bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-xl flex items-center justify-center gap-2 font-medium transition-colors shadow-lg shadow-indigo-600/20"
          >
            <Plus className="w-5 h-5" /> Thêm Quản trị viên
          </button>
        )}
      </div>

      <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-50 dark:bg-zinc-900/80 text-gray-500 dark:text-zinc-400 border-b border-gray-200 dark:border-zinc-800/50">
              <tr>
                <th className="px-6 py-4 font-medium">Người dùng</th>
                <th className="px-6 py-4 font-medium text-center">Sản phẩm</th>
                <th className="px-6 py-4 font-medium text-center">Đơn hàng</th>
                <th className="px-6 py-4 font-medium text-center">Trang chủ</th>
                <th className="px-6 py-4 font-medium text-center">Mã GT</th>
                <th className="px-6 py-4 font-medium text-center">Thiết lập</th>
                <th className="px-6 py-4 font-medium text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-zinc-800/50">
              {displayAdmins.map((admin) => (
                <tr key={admin.id} className="hover:bg-gray-50 dark:hover:bg-zinc-800/30 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-indigo-100 dark:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
                        {admin.isSuperAdmin ? <ShieldAlert className="w-5 h-5" /> : <User className="w-5 h-5" />}
                      </div>
                      <div>
                        <div className="font-medium text-gray-900 dark:text-white">{admin.name || admin.email.split('@')[0]}</div>
                        <div className="text-xs text-gray-500 dark:text-zinc-400 flex items-center gap-1 mt-0.5">
                          <Mail className="w-3 h-3" /> {admin.email}
                        </div>
                      </div>
                    </div>
                  </td>

                  {/* Modules Permissions */}
                  {[
                    { key: 'manageProducts' as keyof IAdminPermissions },
                    { key: 'manageOrders' as keyof IAdminPermissions },
                    { key: 'manageHomepage' as keyof IAdminPermissions },
                    { key: 'manageDiscounts' as keyof IAdminPermissions },
                    { key: 'manageSettings' as keyof IAdminPermissions },
                  ].map((module) => (
                    <td key={module.key} className="px-6 py-4 text-center">
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input 
                          type="checkbox" 
                          className="sr-only peer" 
                          checked={admin.permissions?.[module.key] || false}
                          disabled={admin.isSuperAdmin || (!currentUser?.isSuperAdmin && !currentUser?.permissions.manageRoles)}
                          onChange={() => handleTogglePermission(admin.id, module.key, admin.permissions?.[module.key] || false)} 
                        />
                        <div className="w-11 h-6 bg-gray-200 dark:bg-zinc-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
                      </label>
                    </td>
                  ))}

                  <td className="px-6 py-4 text-right">
                    {!admin.isSuperAdmin && (currentUser?.isSuperAdmin || currentUser?.permissions.manageRoles) && (
                      <button 
                        onClick={() => handleDeleteAdmin(admin.id)}
                        className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors"
                        title="Xóa Quyền"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white dark:bg-zinc-900 rounded-2xl p-6 sm:p-8 max-w-md w-full shadow-2xl border border-gray-200 dark:border-zinc-800">
            <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-6">Thêm Quản trị viên</h3>
            <form onSubmit={handleAddAdmin}>
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Email Quản trị viên gốc</label>
                <input
                  type="email"
                  required
                  value={newAdminEmail}
                  onChange={e => setNewAdminEmail(e.target.value)}
                  placeholder="VD: nv.a@gmail.com"
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none transition-all"
                />
                <p className="text-xs text-gray-500 mt-2">Lưu ý: Mặc định người dùng mới sẽ bị tắt tất cả các quyền. Vui lòng bật quyền cho họ sau khi thêm.</p>
              </div>
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="flex-1 px-4 py-2.5 rounded-xl font-medium text-gray-700 dark:text-zinc-300 bg-gray-100 dark:bg-zinc-800 hover:bg-gray-200 dark:hover:bg-zinc-700 transition-colors"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2.5 rounded-xl font-bold text-white bg-indigo-600 hover:bg-indigo-700 transition-colors shadow-lg shadow-indigo-600/20"
                >
                  Thêm
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
