import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, onAuthStateChanged, signInWithPopup, signOut } from 'firebase/auth';
import { doc, onSnapshot } from 'firebase/firestore';
import { auth, googleProvider, db } from '../firebase';
import { AdminUser, AdminPermissions } from '../types';

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
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
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
    
    const isSuperAdmin = user.email === 'oneloveonepeopleforever@gmail.com';

    const unsubscribe = onSnapshot(doc(db, 'adminUsers', user.email || user.uid), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data() as AdminUser;
        setAdminUser({
          ...data,
          isSuperAdmin: isSuperAdmin
        });
      } else if (isSuperAdmin) {
        setAdminUser({
          id: user.uid,
          email: user.email!,
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
        });
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
