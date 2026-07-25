import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { signInWithEmailAndPassword, signOut as firebaseSignOut } from 'firebase/auth';
import { firebaseAuth } from './firebase';
import { exchangeFirebaseToken } from './apiClient';
import type { DittoUser } from './types';

const STORAGE_KEY = 'ditto-admin-session';

interface StoredSession {
  accessToken: string;
  user: DittoUser;
}

interface AuthContextValue {
  status: 'loading' | 'signed-out' | 'signed-in';
  accessToken: string | null;
  user: DittoUser | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function loadSession(): StoredSession | null {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as StoredSession;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<StoredSession | null>(null);
  const [status, setStatus] = useState<AuthContextValue['status']>('loading');

  useEffect(() => {
    const stored = loadSession();
    if (stored && stored.user.role === 'ADMIN') {
      setSession(stored);
      setStatus('signed-in');
    } else {
      setStatus('signed-out');
    }
  }, []);

  async function login(email: string, password: string) {
    const credential = await signInWithEmailAndPassword(firebaseAuth, email, password);
    const idToken = await credential.user.getIdToken();
    const { accessToken, user } = await exchangeFirebaseToken(idToken);

    if (user.role !== 'ADMIN') {
      await firebaseSignOut(firebaseAuth);
      throw new Error('This account does not have admin access.');
    }

    const next: StoredSession = { accessToken, user };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    setSession(next);
    setStatus('signed-in');
  }

  async function logout() {
    await firebaseSignOut(firebaseAuth).catch(() => undefined);
    localStorage.removeItem(STORAGE_KEY);
    setSession(null);
    setStatus('signed-out');
  }

  return (
    <AuthContext.Provider
      value={{
        status,
        accessToken: session?.accessToken ?? null,
        user: session?.user ?? null,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
