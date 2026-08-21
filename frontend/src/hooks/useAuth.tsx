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
}

const AuthCtx = createContext<AuthState>({
  loading: true, session: null, profile: null,
  refreshProfile: async () => {}, signOut: async () => {},
});

export const useAuth = () => useContext(AuthCtx);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [loading, setLoading] = useState(true);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);

  const loadProfile = useCallback(async (s: Session | null) => {
    if (!s) { setProfile(null); return; }
    const { data } = await supabase.from('profiles').select('*').eq('id', s.user.id).single();
    setProfile((data as Profile) ?? null);
  }, []);

  useEffect(() => {
    // Session restoration on refresh — Supabase persists to localStorage (§9).
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

  const signOut = useCallback(async () => { await supabase.auth.signOut(); }, []);

  return (
    <AuthCtx.Provider value={{ loading, session, profile, refreshProfile, signOut }}>
      {children}
    </AuthCtx.Provider>
  );
}

function FullPageSpinner() {
  return (
    <div className="min-h-screen grid place-items-center bg-canvas">
      <div className="animate-pulse text-ink-faint text-sm font-medium">Loading…</div>
    </div>
  );
}

/** Requires an authenticated session; optionally a specific role;
 *  optionally completed onboarding. Wrong role → own dashboard (§13). */
export function Protected({ role, children, allowIncompleteOnboarding = false }: {
  role?: Role; children: ReactNode; allowIncompleteOnboarding?: boolean;
}) {
  const { loading, session, profile } = useAuth();
  const location = useLocation();
  if (loading) return <FullPageSpinner />;
  if (!session) return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  if (!profile) return <Navigate to="/signup" replace />;
  if (!profile.onboarding_complete && !allowIncompleteOnboarding) {
    return <Navigate to={profile.role === 'sme' ? '/onboarding/sme' : '/onboarding/owner'} replace />;
  }
  if (role && profile.role !== role) {
    return <Navigate to={profile.role === 'sme' ? '/dashboard/sme' : '/dashboard/owner'} replace />;
  }
  return <>{children}</>;
}
