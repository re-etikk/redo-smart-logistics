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
    if (!s) { setProfile(null); return null; }
    try {
      let { data } = await supabase.from('profiles').select('*').eq('id', s.user.id).single();
      if (!data) {
        // Auto-provision profile row for new Google OAuth or SSO user
        const meta = s.user.user_metadata || {};
        const newProfile: Profile = {
          id: s.user.id,
          role: (meta.role as Role) || 'sme',
          full_name: meta.full_name || meta.name || s.user.email?.split('@')[0] || 'REDO Partner',
          company_name: 'REDO Logistics Partner',
          phone: s.user.phone || '+91 9876543210',
          onboarding_complete: true,
        };
        await supabase.from('profiles').upsert([newProfile]);
        data = newProfile;
      }
      setProfile((data as Profile) ?? null);
      return (data as Profile);
    } catch {
      // Fallback profile for seamless navigation
      const meta = s.user.user_metadata || {};
      const fallback: Profile = {
        id: s.user.id,
        role: 'sme',
        full_name: meta.full_name || meta.name || s.user.email?.split('@')[0] || 'REDO Partner',
        company_name: 'REDO Logistics Partner',
        phone: '+91 9876543210',
        onboarding_complete: true,
      };
      setProfile(fallback);
      return fallback;
    }
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data }) => {
      setSession(data.session);
      if (data.session) {
        await loadProfile(data.session);
      }
      setLoading(false);
    });

    const { data: sub } = supabase.auth.onAuthStateChange(async (_evt, s) => {
      setSession(s);
      if (s) {
        await loadProfile(s);
      }
      setLoading(false);
    });

    return () => sub.subscription.unsubscribe();
  }, [loadProfile]);

  const refreshProfile = useCallback(async () => {
    const { data } = await supabase.auth.getSession();
    await loadProfile(data.session);
  }, [loadProfile]);

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    setSession(null);
    setProfile(null);
  }, []);

  return (
    <AuthCtx.Provider value={{ loading, session, profile, refreshProfile, signOut }}>
      {children}
    </AuthCtx.Provider>
  );
}

function FullPageSpinner() {
  return (
    <div className="min-h-screen grid place-items-center bg-[#FAF9F6]">
      <div className="animate-pulse text-slate-700 text-sm font-black flex items-center gap-2">
        <span className="w-3 h-3 rounded-full bg-[#FFC800]"></span> Loading Redo Logistics...
      </div>
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
