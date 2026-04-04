import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, onAuthStateChanged, signInWithPopup, signOut } from 'firebase/auth';
import { doc, onSnapshot, setDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { auth, googleProvider, db } from '../firebase';
import { AdminUser, AdminPermissions, AppUser } from '../types';
import { toast } from 'sonner';

interface AuthContextType {
  user: User | null;
  adminUser: AdminUser | null;
  isAdmin: boolean;
  loading: boolean;
  login: () => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({} as AuthContextType);

export const useAuth = () => useContext(AuthContext);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      if (currentUser) {
        try {
          const userRef = doc(db, 'users', currentUser.uid);
          const userSnap = await getDoc(userRef);
          
          if (userSnap.exists()) {
            const userData = userSnap.data() as AppUser;
            if (userData.isBanned) {
              await signOut(auth);
              toast.error('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.', { duration: 5000 });
              setUser(null);
              setAdminUser(null);
              setLoading(false);
              return;
            }
            
            // Update last login
            await setDoc(userRef, {
              lastLoginAt: serverTimestamp(),
              email: currentUser.email,
              displayName: currentUser.displayName,
              photoURL: currentUser.photoURL,
            }, { merge: true });
          } else {
            // Create new user profile
            const newUser: Partial<AppUser> = {
              uid: currentUser.uid,
              email: currentUser.email,
              displayName: currentUser.displayName,
              photoURL: currentUser.photoURL,
              isBanned: false,
              tier: 'bronze',
              points: 0,
              totalOrders: 0,
              totalSpent: 0,
              createdAt: serverTimestamp(),
              lastLoginAt: serverTimestamp()
            };
            await setDoc(userRef, newUser);
          }
        } catch (error) {
          console.error("Lỗi khi kiểm tra hoặc ghi thông tin user:", error);
        }
      }
      
      setUser(currentUser);
      if (!currentUser) {
        setAdminUser(null);
        setLoading(false);
      }
    });
    return unsubscribe;
  }, []);

  useEffect(() => {
    if (!user) return;
    const userEmail = user.email || user.providerData?.[0]?.email || '';
    
    // Make sure case-insensitive comparison and stripped of spaces
    const isSuperAdmin = userEmail.toLowerCase().trim() === 'oneloveonepeopleforever@gmail.com';

    const defaultSuperAdmin: AdminUser = {
      id: user.uid,
      email: user.email || 'oneloveonepeopleforever@gmail.com',
      name: user.displayName || 'Super Admin',
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
      isSuperAdmin: true
    };

    // If SuperAdmin, bypass Firestore completely to guarantee 100% access without any network/rules blocking
    if (isSuperAdmin) {
      setAdminUser(defaultSuperAdmin);
      setLoading(false);
      return;
    }

    const unsubscribe = onSnapshot(doc(db, 'users', user.uid), async (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data() as AppUser;
        
        // REAL-TIME BAN ENFORCEMENT
        if (data.isBanned) {
          toast.error('Tài khoản của bạn đã bị khóa bởi Quản trị viên.', { duration: 5000 });
          await signOut(auth);
          setUser(null);
          setAdminUser(null);
          setLoading(false);
          return;
        }

        if (data.adminPermissions) {
          setAdminUser({
            id: user.uid,
            email: data.email || user.email || '',
            name: data.displayName || user.displayName || 'Admin',
            permissions: data.adminPermissions,
            createdAt: data.createdAt,
            updatedAt: data.lastLoginAt,
            isSuperAdmin: false
          });
        } else {
          setAdminUser(null);
        }
      } else {
        setAdminUser(null);
      }
      setLoading(false);
    }, (error) => {
      console.error("Error fetching admin status:", error);
      setAdminUser(null);
      setLoading(false);
    });

    return unsubscribe;
  }, [user]);

  const login = async () => {
    try {
      await signInWithPopup(auth, googleProvider);
    } catch (error) {
      console.error('Login failed', error);
    }
  };

  const logout = async () => {
    await signOut(auth);
  };

  const isAdmin = !!adminUser;

  return (
    <AuthContext.Provider value={{ user, adminUser, isAdmin, loading, login, logout }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
