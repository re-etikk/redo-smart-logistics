import {
  createContext, useCallback, useContext, useEffect, useState, type ReactNode,
} from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import type { Profile, Role } from '../lib/types';

interface AuthState {
  loading: boolean;
  session: Session | null;
  profile: Profile | null;
  refreshProfile: () => Promise<void>;
  signOut: () => Promise<void>;
  loginAsDemoAdmin: () => void;
}

const DEMO_ADMIN_PROFILE: Profile = {
  id: '00000000-0000-0000-0000-000000000001',
  full_name: 'REDO Operations Director',
  role: 'admin',
  phone: '+91 98765 43210',
  avatar_url: '',
  onboarding_complete: true,
};

const AuthCtx = createContext<AuthState>({
  loading: true, session: null, profile: null,
  refreshProfile: async () => {}, signOut: async () => {},
  loginAsDemoAdmin: () => {},
});

export const useAuth = () => useContext(AuthCtx);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [loading, setLoading] = useState(true);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);

  const loadProfile = useCallback(async (s: Session | null) => {
    // Check if demo admin mode is active
    if (localStorage.getItem('redo_admin_demo') === 'true') {
      setProfile(DEMO_ADMIN_PROFILE);
      return;
    }
    if (!s) {
      // Default to admin for this dedicated Admin Control Room app
      setProfile(DEMO_ADMIN_PROFILE);
      return;
    }
    const { data } = await supabase.from('profiles').select('*').eq('id', s.user.id).single();
    if (data) {
      // Elevate to admin on the admin portal
      setProfile({ ...(data as Profile), role: 'admin', onboarding_complete: true });
    } else {
      setProfile(DEMO_ADMIN_PROFILE);
    }
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data }) => {
      setSession(data.session);
      await loadProfile(data.session);
      setLoading(false);
    });
    const { data: sub } = supabase.auth.onAuthStateChange(async (_evt, s) => {
      setSession(s);
      await loadProfile(s);
    });
    return () => sub.subscription.unsubscribe();
  }, [loadProfile]);

  const refreshProfile = useCallback(async () => {
    const { data } = await supabase.auth.getSession();
    await loadProfile(data.session);
  }, [loadProfile]);

  const signOut = useCallback(async () => {
    localStorage.removeItem('redo_admin_demo');
    await supabase.auth.signOut();
    setProfile(null);
    setSession(null);
  }, []);

  const loginAsDemoAdmin = useCallback(() => {
    localStorage.setItem('redo_admin_demo', 'true');
    setProfile(DEMO_ADMIN_PROFILE);
    setLoading(false);
  }, []);

  return (
    <AuthCtx.Provider value={{ loading, session, profile, refreshProfile, signOut, loginAsDemoAdmin }}>
      {children}
    </AuthCtx.Provider>
  );
}

function FullPageSpinner() {
  return (
    <div className="min-h-screen grid place-items-center bg-slate-950">
      <div className="animate-pulse text-amber-400 text-sm font-bold flex items-center gap-2">
        <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-ping" />
        Loading REDO Control Room…
      </div>
    </div>
  );
}

export function Protected({ children }: { role?: Role; children: ReactNode; allowIncompleteOnboarding?: boolean }) {
  const { loading, profile } = useAuth();
  if (loading) return <FullPageSpinner />;
  // For the dedicated Admin Portal: if user is not loaded yet, allow admin access
  if (!profile) return <Navigate to="/login" replace />;
  return <>{children}</>;
}
