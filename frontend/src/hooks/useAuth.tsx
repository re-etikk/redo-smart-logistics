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
    if (!s) {
      setProfile(null);
      return;
    }
    try {
      // Use maybeSingle to prevent 406 error when row does not exist yet
      const { data } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", s.user.id)
        .maybeSingle();

      if (data) {
        setProfile(data as Profile);
        return;
      }

      // If no row exists in Supabase table yet, create default profile from metadata
      const userMeta = s.user?.user_metadata || {};
      const defaultProfile: Profile = {
        id: s.user.id,
        role: (userMeta.role as Role) || (s.user.email?.includes("owner") ? "truck_owner" : "sme"),
        full_name: userMeta.full_name || s.user.email?.split("@")[0] || "User",
        phone: userMeta.phone || "",
        company_name: userMeta.company_name || "",
        avatar_url: userMeta.avatar_url || "",
        kyc_verified: true,
        onboarding_complete: false,
      };

      try {
        await supabase.from("profiles").upsert(defaultProfile);
      } catch {}

      setProfile(defaultProfile);
    } catch {
      // Robust fallback so user is NEVER trapped on /signup
      const fallbackProfile: Profile = {
        id: s.user.id,
        role: (s.user?.user_metadata?.role as Role) || "sme",
        full_name: s.user?.user_metadata?.full_name || "User",
        phone: s.user?.user_metadata?.phone || "",
        company_name: "",
        avatar_url: "",
        kyc_verified: true,
        onboarding_complete: false,
      };
      setProfile(fallbackProfile);
    }
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
