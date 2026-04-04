import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, doc, setDoc, query, orderBy } from 'firebase/firestore';
import { db } from '../../firebase';
import { AppUser, AdminPermissions as IAdminPermissions, UserTier } from '../../types';
import { handleFirestoreError, OperationType } from '../../utils/firebaseError';
import { Shield, ShieldAlert, User, Mail, Search, Ban, Medal, ShoppingBag, Edit, X } from 'lucide-react';
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

const TIER_COLORS = {
  bronze: 'bg-orange-100 text-orange-800 border-orange-200 dark:bg-orange-500/20 dark:text-orange-400 dark:border-orange-500/30',
  silver: 'bg-slate-100 text-slate-800 border-slate-200 dark:bg-slate-500/20 dark:text-slate-300 dark:border-slate-500/30',
  gold: 'bg-yellow-100 text-yellow-800 border-yellow-200 dark:bg-yellow-500/20 dark:text-yellow-400 dark:border-yellow-500/30',
  diamond: 'bg-blue-100 text-blue-800 border-blue-200 dark:bg-blue-500/20 dark:text-blue-400 dark:border-blue-500/30',
};

const TIER_LABELS = {
  bronze: 'Đồng',
  silver: 'Bạc',
  gold: 'Vàng',
  diamond: 'Kim Cương',
};

export default function AdminUsers() {
  const { adminUser: currentUser } = useAuth();
  const [users, setUsers] = useState<AppUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Modal states
  const [editingUser, setEditingUser] = useState<AppUser | null>(null);

  useEffect(() => {
    const q = query(collection(db, 'users'), orderBy('lastLoginAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list: AppUser[] = [];
      snapshot.forEach((doc) => {
        list.push({ uid: doc.id, ...doc.data() } as AppUser);
      });
      setUsers(list);
      setLoading(false);
    }, (error) => {
      console.error("Lỗi khi tải danh sách users:", error);
      toast.error('Lỗi khi tải danh sách người dùng (Kiểm tra Firestore Rules)');
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleUpdateTier = async (userId: string, newTier: UserTier) => {
    if (!currentUser?.isSuperAdmin && !currentUser?.permissions.manageRoles) {
      toast.error('Bạn không có quyền quản lý thành viên');
      return;
    }
    
    try {
      await setDoc(doc(db, 'users', userId), { tier: newTier }, { merge: true });
      toast.success('Đã cập nhật hạng thành viên');
    } catch (e) {
      toast.error('Lỗi khi cập nhật hạng');
    }
  };

  const handleToggleBan = async (userId: string, currentBanStatus: boolean) => {
    if (!currentUser?.isSuperAdmin && !currentUser?.permissions.manageRoles) {
      toast.error('Bạn không có quyền quản lý thành viên');
      return;
    }

    if (userId === 'HCcsu4D0FEWV1axlrlyKfzEON953') {
      toast.error('Không thể khóa Super Admin');
      return;
    }
    
    if (window.confirm(`Bạn có chắc chắn muốn ${currentBanStatus ? 'MỞ KHÓA' : 'KHÓA'} tài khoản này?`)) {
      try {
        await setDoc(doc(db, 'users', userId), { isBanned: !currentBanStatus }, { merge: true });
        toast.success(`Đã ${currentBanStatus ? 'mở khóa' : 'khóa'} tài khoản`);
      } catch (e) {
        toast.error('Lỗi khi cập nhật trạng thái');
      }
    }
  };

  const handleSavePermissions = async (userId: string, permissions: IAdminPermissions | null) => {
    try {
      const updateData = permissions ? { adminPermissions: permissions } : { adminPermissions: null };
      await setDoc(doc(db, 'users', userId), updateData, { merge: true });
      toast.success('Đã cấu hình quyền Quản trị viên');
      setEditingUser(null);
    } catch (e) {
      toast.error('Lỗi khi lưu phân quyền');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[40vh]">
        <div className="w-5 h-5 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  // Inject Super Admin visually if missing
  const displayUsers = [...users];
  if (!displayUsers.some(u => u.email === 'oneloveonepeopleforever@gmail.com')) {
    displayUsers.unshift({
      uid: 'superadmin_id',
      email: 'oneloveonepeopleforever@gmail.com',
      displayName: 'Super Admin',
      photoURL: null,
      isBanned: false,
      tier: 'diamond',
      points: 9999,
      totalOrders: 0,
      totalSpent: 0,
      createdAt: new Date(),
      lastLoginAt: new Date(),
      adminPermissions: {
        manageProducts: true,
        manageOrders: true,
        manageHomepage: true,
        manageDiscounts: true,
        manageSettings: true,
        manageRoles: true
      }
    });
  }

  const filteredUsers = displayUsers.filter(u => 
    u.email?.toLowerCase().includes(searchTerm.toLowerCase()) || 
    u.displayName?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
            <User className="w-6 h-6 text-indigo-500" />
            Quản lý Thành viên & Phân quyền
          </h2>
          <p className="text-sm text-slate-500 dark:text-zinc-400 mt-1">
            Quản lý khách hàng, thăng hạng VIP, khóa tài khoản chống spam và cấp quyền cho Ban quản trị.
          </p>
        </div>
        <div className="relative w-full sm:w-80">
          <input
            type="text"
            placeholder="Tìm theo email hoặc tên..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl pl-10 pr-4 py-2 text-sm text-slate-900 dark:text-white focus:ring-1 focus:ring-indigo-500"
          />
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
        </div>
      </div>

      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 shadow-sm rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 dark:bg-zinc-900/80 text-slate-500 dark:text-zinc-400 border-b border-slate-200 dark:border-zinc-800/50">
              <tr>
                <th className="px-6 py-4 font-medium">Người dùng</th>
                <th className="px-6 py-4 font-medium text-center">Xếp hạng</th>
                <th className="px-6 py-4 font-medium text-center">Mua hàng</th>
                <th className="px-6 py-4 font-medium text-center">Tình trạng</th>
                <th className="px-6 py-4 font-medium text-right">Vai trò / Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-zinc-800/50">
              {filteredUsers.map((user) => {
                const isSuperAdmin = user.email?.toLowerCase() === 'oneloveonepeopleforever@gmail.com';
                const isAdmin = isSuperAdmin || !!user.adminPermissions;
                
                return (
                  <tr key={user.uid} className={`hover:bg-slate-50 dark:hover:bg-zinc-800/30 transition-colors ${user.isBanned ? 'opacity-75' : ''}`}>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="relative">
                          {user.photoURL ? (
                            <img src={user.photoURL} alt={user.displayName || ''} className="w-10 h-10 rounded-full border border-slate-200 dark:border-zinc-700 object-cover" />
                          ) : (
                            <div className="w-10 h-10 rounded-full bg-indigo-100 dark:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
                              <User className="w-5 h-5" />
                            </div>
                          )}
                          {isAdmin && (
                            <div className="absolute -bottom-1 -right-1 bg-amber-500 text-white p-0.5 rounded-full border-2 border-white dark:border-zinc-900" title="Quản trị viên">
                              <ShieldAlert className="w-3 h-3" />
                            </div>
                          )}
                        </div>
                        <div>
                          <div className={`font-medium ${user.isBanned ? 'text-slate-400 dark:text-zinc-500 line-through' : 'text-slate-900 dark:text-white'}`}>
                            {user.displayName || user.email?.split('@')[0]}
                          </div>
                          <div className="text-xs text-slate-500 dark:text-zinc-400 flex items-center gap-1 mt-0.5">
                            <Mail className="w-3 h-3" /> {user.email}
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* Tier Column */}
                    <td className="px-6 py-4 text-center">
                      <select 
                        value={user.tier || 'bronze'}
                        onChange={(e) => handleUpdateTier(user.uid, e.target.value as UserTier)}
                        disabled={!currentUser?.isSuperAdmin && !currentUser?.permissions.manageRoles}
                        className={`text-xs px-2.5 py-1.5 rounded-lg border font-medium outline-none cursor-pointer ${TIER_COLORS[user.tier || 'bronze']} appearance-none text-center`}
                      >
                        <option value="bronze">Đồng</option>
                        <option value="silver">Bạc</option>
                        <option value="gold">Vàng</option>
                        <option value="diamond">Kim cương</option>
                      </select>
                    </td>

                    {/* Stats Column */}
                    <td className="px-6 py-4 text-center">
                      <div className="flex flex-col items-center justify-center">
                        <div className="flex items-center gap-1 text-slate-700 dark:text-zinc-300 font-medium">
                          <ShoppingBag className="w-3.5 h-3.5" /> {(user.totalOrders || 0)} đơn
                        </div>
                        <div className="text-xs text-emerald-600 dark:text-emerald-500 mt-1 flex items-center gap-1">
                          <Medal className="w-3.5 h-3.5" /> {user.points || 0} đ
                        </div>
                      </div>
                    </td>

                    {/* Ban Status */}
                    <td className="px-6 py-4 text-center">
                      {isSuperAdmin ? (
                        <span className="text-xs font-medium text-emerald-600 bg-emerald-50 dark:bg-emerald-500/10 dark:text-emerald-400 px-2.5 py-1 rounded-full border border-emerald-200 dark:border-emerald-500/20">Active</span>
                      ) : (
                        <button
                          onClick={() => handleToggleBan(user.uid, user.isBanned)}
                          disabled={!currentUser?.isSuperAdmin && !currentUser?.permissions.manageRoles}
                          className={`flex items-center gap-1.5 mx-auto text-xs font-medium px-2.5 py-1 rounded-full border transition-colors ${
                            user.isBanned 
                              ? 'bg-indigo-50 text-indigo-700 border-indigo-200 hover:bg-indigo-100 dark:bg-indigo-500/20 dark:text-indigo-400 dark:border-indigo-500/30' 
                              : 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100 dark:bg-emerald-500/20 dark:text-emerald-400 dark:border-emerald-500/30'
                          }`}
                        >
                          {user.isBanned ? <Ban className="w-3.5 h-3.5" /> : <Shield className="w-3.5 h-3.5" />}
                          {user.isBanned ? 'Bị Khóa' : 'Hoạt động'}
                        </button>
                      )}
                    </td>

                    <td className="px-6 py-4 text-right">
                      {!isSuperAdmin && (currentUser?.isSuperAdmin || currentUser?.permissions.manageRoles) && (
                        <button 
                          onClick={() => setEditingUser(user)}
                          className="px-3 py-1.5 bg-indigo-50 text-indigo-600 dark:bg-indigo-500/10 dark:text-indigo-400 hover:bg-indigo-100 dark:hover:bg-indigo-500/20 rounded-lg text-xs font-medium transition-colors border border-indigo-200 dark:border-indigo-500/20 inline-flex items-center gap-1.5"
                        >
                          <Edit className="w-3.5 h-3.5" /> 
                          {isAdmin ? 'Sửa quyền' : 'Cấp Admin'}
                        </button>
                      )}
                      {isSuperAdmin && (
                        <span className="text-xs text-slate-400 dark:text-zinc-500 font-medium px-3 py-1.5 border border-transparent">
                          Không thể sửa
                        </span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {editingUser && (
        <PermissionModal 
          user={editingUser} 
          onClose={() => setEditingUser(null)} 
          onSave={(permissions) => handleSavePermissions(editingUser.uid, permissions)}
        />
      )}
    </div>
  );
}

function PermissionModal({ user, onClose, onSave }: { user: AppUser, onClose: () => void, onSave: (p: IAdminPermissions | null) => void }) {
  const [permissions, setPermissions] = useState<IAdminPermissions>(
    user.adminPermissions || DEFAULT_PERMISSIONS
  );
  const [isAdmin, setIsAdmin] = useState<boolean>(!!user.adminPermissions);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white dark:bg-zinc-900 rounded-xl max-w-lg w-full shadow-2xl border border-slate-200 dark:border-zinc-800 overflow-hidden">
        <div className="p-6 border-b border-slate-100 dark:border-zinc-800 flex justify-between items-center bg-slate-50 dark:bg-zinc-950">
          <h3 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
            <ShieldAlert className="w-5 h-5 text-amber-500" />
            Cấu hình quyền Admin
          </h3>
          <button onClick={onClose} className="p-2 text-slate-400 hover:text-indigo-500 bg-slate-100 dark:bg-zinc-800 rounded-full">
            <X className="w-4 h-4" />
          </button>
        </div>
        
        <div className="p-6">
          <div className="flex items-center gap-3 mb-6 p-4 bg-amber-50 dark:bg-amber-500/10 border border-amber-100 dark:border-amber-500/20 rounded-xl">
            <img src={user.photoURL || ''} className="w-12 h-12 rounded-full hidden sm:block bg-slate-200" alt="" />
            <div>
              <p className="font-bold text-slate-900 dark:text-white">{user.displayName || user.email}</p>
              <p className="text-sm text-slate-500 dark:text-zinc-400">{user.email}</p>
            </div>
          </div>

          <label className="flex items-center gap-3 p-4 border border-slate-200 dark:border-zinc-700 rounded-xl cursor-pointer hover:bg-slate-50 dark:hover:bg-zinc-800/50 transition-colors mb-6">
            <input 
              type="checkbox" 
              checked={isAdmin} 
              onChange={e => setIsAdmin(e.target.checked)} 
              className="w-5 h-5 text-indigo-600 rounded focus:ring-indigo-500 border-slate-300"
            />
            <div>
              <div className="font-bold text-slate-900 dark:text-white">Cấp quyền Quản trị viên (Admin)</div>
              <div className="text-xs text-slate-500">Giới hạn trong các module được phép bên dưới</div>
            </div>
          </label>

          <div className={`space-y-4 transition-all ${!isAdmin ? 'opacity-50 pointer-events-none' : ''}`}>
            <h4 className="font-medium text-sm text-slate-700 dark:text-zinc-300 uppercase tracking-wider">Module được phép truy cập</h4>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {[
                { key: 'manageProducts' as keyof IAdminPermissions, label: 'Quản lý Sản phẩm' },
                { key: 'manageOrders' as keyof IAdminPermissions, label: 'Quản lý Đơn hàng' },
                { key: 'manageHomepage' as keyof IAdminPermissions, label: 'Tùy chỉnh Giao diện' },
                { key: 'manageDiscounts' as keyof IAdminPermissions, label: 'Mã Giảm giá' },
                { key: 'manageSettings' as keyof IAdminPermissions, label: 'Thiết lập Hệ thống' },
                { key: 'manageRoles' as keyof IAdminPermissions, label: 'Quản lý Thành viên' },
              ].map(module => (
                <label key={module.key} className="flex items-center justify-between p-3 border border-slate-100 dark:border-zinc-800 rounded-lg cursor-pointer hover:bg-slate-50 dark:hover:bg-zinc-800/30">
                  <span className="text-sm font-medium text-slate-700 dark:text-zinc-300">{module.label}</span>
                  <div className="relative inline-flex items-center">
                    <input 
                      type="checkbox" 
                      className="sr-only peer" 
                      checked={permissions[module.key]}
                      onChange={(e) => setPermissions({...permissions, [module.key]: e.target.checked})}
                    />
                    <div className="w-9 h-5 bg-slate-200 dark:bg-zinc-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-indigo-500"></div>
                  </div>
                </label>
              ))}
            </div>
          </div>
        </div>
        
        <div className="p-4 sm:p-6 border-t border-slate-100 dark:border-zinc-800 bg-slate-50 dark:bg-zinc-950 flex justify-end gap-3">
          <button onClick={onClose} className="px-5 py-2 rounded-xl text-sm font-medium text-slate-700 dark:text-zinc-300 hover:bg-slate-200 dark:hover:bg-zinc-800 transition-colors">
            Hủy
          </button>
          <button 
            onClick={() => onSave(isAdmin ? permissions : null)}
            className="px-5 py-2 rounded-xl text-sm font-bold text-white bg-indigo-600 hover:bg-indigo-700 transition-colors shadow-sm"
          >
            Lưu thay đổi
          </button>
        </div>
      </div>
    </div>
  );
}
