import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { User, getRedirectResult, onAuthStateChanged, signInWithRedirect, signOut } from 'firebase/auth';
import { doc, onSnapshot, setDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { auth, googleProvider, db } from '../firebase';
import { AdminUser, AdminPermissions, AppUser } from '../types';
import { toast } from 'sonner';
import { googleLoginErrorMessage } from '../utils/googleAuthFlow';

const REDIRECT_LOGIN_KEY = 'tqs-shop-google-redirect-pending';

interface AuthContextType {
  user: User | null;
  appUser: AppUser | null;
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
  const [appUser, setAppUser] = useState<AppUser | null>(null);
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);
  const loginInFlight = useRef(false);

  useEffect(() => {
    // A redirect returns to this PWA in a new page load. Consume Firebase's
    // result once, and surface failures that previously disappeared on reload.
    if (sessionStorage.getItem(REDIRECT_LOGIN_KEY) !== '1') return;
    void getRedirectResult(auth).then(async (result) => {
      // Persistence restoration can finish after the redirect result is read.
      await auth.authStateReady();
      if (result || auth.currentUser) {
        toast.success('Đăng nhập Google thành công.');
      } else {
        toast.error('Google chưa hoàn tất đăng nhập. Hãy bấm Đăng nhập để thử lại.');
      }
    }).catch((error) => {
      console.error('Google redirect login failed', error);
      const message = googleLoginErrorMessage(error);
      if (message) toast.error(message, { duration: 7000 });
    }).finally(() => {
      sessionStorage.removeItem(REDIRECT_LOGIN_KEY);
    });
  }, []);

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
              setAppUser(null);
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
              role: 'customer',
              isBanned: false,
              tier: 'bronze',
              points: 0,
              totalOrders: 0,
              totalSpent: 0,
              rewardReversalDebt: 0,
              adminPermissions: null,
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
        setAppUser(null);
        setLoading(false);
      }
    });
    return unsubscribe;
  }, []);

  useEffect(() => {
    if (!user) return;
    let active = true;
    let unsubscribe: (() => void) | undefined;

    const fullPermissions: AdminPermissions = {
      manageProducts: true,
      manageOrders: true,
      manageHomepage: true,
      manageDiscounts: true,
      manageSettings: true,
      manageRoles: true,
      manageRewards: true,
      managePosts: true,
      manageGameAccess: true,
      manageGamePool: true,
    };

    const subscribeToAuthority = async () => {
      let hasSuperAdminClaim = false;
      try {
        // Claims are set server-side and Firebase may otherwise keep the old
        // ID token for up to an hour. Force one refresh here so a newly
        // provisioned Super Admin does not remain locked out after signing
        // in with an already-open session.
        const tokenResult = await user.getIdTokenResult(true);
        hasSuperAdminClaim = tokenResult.claims.super_admin === true;
      } catch (error) {
        console.error('Error reading Firebase authority claims:', error);
      }

      if (!active) return;

      unsubscribe = onSnapshot(doc(db, 'users', user.uid), async (docSnap) => {
        if (!active) return;

        if (!docSnap.exists()) {
          setAppUser(null);
          setAdminUser(hasSuperAdminClaim ? {
            id: user.uid,
            email: user.email || '',
            name: user.displayName || 'Super Admin',
            permissions: fullPermissions,
            createdAt: new Date(),
            updatedAt: new Date(),
            isSuperAdmin: true,
          } : null);
          setLoading(false);
          return;
        }

        const data = docSnap.data() as AppUser;
        setAppUser(data);

        // REAL-TIME BAN ENFORCEMENT
        if (data.isBanned) {
          toast.error('Tài khoản của bạn đã bị khóa bởi Quản trị viên.', { duration: 5000 });
          await signOut(auth);
          if (active) {
            setUser(null);
            setAdminUser(null);
            setAppUser(null);
            setLoading(false);
          }
          return;
        }

        const isSuperAdmin = hasSuperAdminClaim;
        if (isSuperAdmin) {
          setAdminUser({
            id: user.uid,
            email: data.email || user.email || '',
            name: data.displayName || user.displayName || 'Super Admin',
            permissions: fullPermissions,
            createdAt: data.createdAt,
            updatedAt: data.lastLoginAt,
            isSuperAdmin: true,
          });
        } else if (data.role === 'admin' && data.adminPermissions) {
          setAdminUser({
            id: user.uid,
            email: data.email || user.email || '',
            name: data.displayName || user.displayName || 'Admin',
            permissions: data.adminPermissions,
            createdAt: data.createdAt,
            updatedAt: data.lastLoginAt,
            isSuperAdmin: false,
          });
        } else {
          setAdminUser(null);
        }
        setLoading(false);
      }, (error) => {
        console.error('Error fetching admin status:', error);
        if (active) {
          setAdminUser(null);
          setLoading(false);
        }
      });
    };

    void subscribeToAuthority();
    return () => {
      active = false;
      unsubscribe?.();
    };
  }, [user]);

  const login = async (): Promise<void> => {
    if (loginInFlight.current) return;
    loginInFlight.current = true;
    try {
      // Phát hiện các trình duyệt nhúng trong ứng dụng (Facebook, Zalo, Instagram, TikTok...)
      const ua = navigator.userAgent || navigator.vendor || (window as any).opera;
      const isInAppBrowser = /FBAN|FBAV|Instagram|Zalo|TikTok|Line|Snapchat|Viber/i.test(ua);

      if (isInAppBrowser) {
        toast.error('Trình duyệt này chặn đăng nhập Google. Vui lòng chọn "Mở bằng trình duyệt" (Chrome/Safari) từ menu để tiếp tục.', {
          duration: 10000,
        });
        return;
      }

      // Redirect in the current tab on Safari, Chrome and installed PWAs.
      // Firebase restores the session after Google returns to this URL.
      sessionStorage.setItem(REDIRECT_LOGIN_KEY, '1');
      await signInWithRedirect(auth, googleProvider);
    } catch (error: any) {
      console.error('Login failed', error);
      sessionStorage.removeItem(REDIRECT_LOGIN_KEY);
      const message = googleLoginErrorMessage(error);
      if (message) toast.error(message, { duration: 7000 });
    } finally {
      loginInFlight.current = false;
    }
  };

  const logout = async () => {
    await signOut(auth);
  };

  const isAdmin = !!adminUser;

  return (
    <AuthContext.Provider value={{ user, appUser, adminUser, isAdmin, loading, login, logout }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
