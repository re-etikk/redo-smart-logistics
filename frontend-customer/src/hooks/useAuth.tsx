import {
  createContext, useCallback, useContext, useEffect, useState, type ReactNode,
} from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import type { Session, AuthChangeEvent } from '@supabase/supabase-js';
import { supabase } from "../lib/supabase";
import type { Profile } from "../lib/types";

interface AuthState {
  loading: boolean;
  session: Session | null;
  profile: Profile | null;
  refreshProfile: () => Promise<void>;
  signOut: () => Promise<void>;
}

const LOCAL_AUTH_KEY = "redo_auth_customer_v1";

const AuthCtx = createContext<AuthState>({
  loading: true,
  session: null,
  profile: null,
  refreshProfile: async () => {},
  signOut: async () => {},
});

export const useAuth = () => useContext(AuthCtx);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [loading, setLoading] = useState(true);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);

  const getLocalUser = useCallback((): Profile | null => {
    if (typeof window === 'undefined') return null;
    try {
      const stored = localStorage.getItem(LOCAL_AUTH_KEY);
      if (stored) return JSON.parse(stored);
      const demoRole = localStorage.getItem("redo_demo_role");
      if (demoRole === "sme") {
        return {
          id: "demo-customer",
          role: "sme",
          full_name: "Customer Account",
          company_name: "REDO Customer",
          phone: "+91 9876543210",
          onboarding_complete: true,
        };
      }
    } catch {}
    return null;
  }, []);

  const loadProfile = useCallback(async (s: Session | null) => {
    if (!s) {
      const local = getLocalUser();
      setProfile(local);
      return local;
    }
    try {
      let { data } = await supabase.from('profiles').select('*').eq('id', s.user.id).single();
      if (!data) {
        const meta = s.user.user_metadata || {};
        const newProfile: Profile = {
          id: s.user.id,
          role: 'sme',
          full_name: meta.full_name || meta.name || s.user.email?.split('@')[0] || 'REDO Customer',
          company_name: meta.company_name || 'REDO Customer',
          phone: s.user.phone || '+91 9876543210',
          onboarding_complete: true,
        };
        await supabase.from('profiles').upsert([newProfile]);
        data = newProfile;
      }
      setProfile((data as Profile) ?? null);
      return data as Profile;
    } catch {
      const meta = s.user.user_metadata || {};
      const fallback: Profile = {
        id: s.user.id,
        role: 'sme',
        full_name: meta.full_name || s.user.email?.split('@')[0] || 'REDO Customer',
        company_name: 'REDO Customer',
        phone: '+91 9876543210',
        onboarding_complete: true,
      };
      setProfile(fallback);
      return fallback;
    }
  }, [getLocalUser]);

  useEffect(() => {
    const handleSession = async (s: Session | null) => {
      setSession(s);
      await loadProfile(s);
      if (s && window.location.hash.includes("access_token")) {
        window.history.replaceState(null, "", window.location.pathname);
      }
      setLoading(false);
    };

    supabase.auth.getSession().then(({ data }: { data: { session: Session | null } }) => {
      handleSession(data.session);
    });

    const { data: sub } = supabase.auth.onAuthStateChange((_evt: AuthChangeEvent, s: Session | null) => {
      handleSession(s);
    });

    const handleLocalAuthChanged = () => {
      const local = getLocalUser();
      if (local) {
        setProfile(local);
      }
    };
    window.addEventListener("redo_local_auth_changed", handleLocalAuthChanged);

    return () => {
      sub.subscription.unsubscribe();
      window.removeEventListener("redo_local_auth_changed", handleLocalAuthChanged);
    };
  }, [loadProfile, getLocalUser]);

  const refreshProfile = useCallback(async () => {
    const { data } = await supabase.auth.getSession();
    await loadProfile(data.session);
  }, [loadProfile]);

  const signOut = useCallback(async () => {
    try {
      await supabase.auth.signOut();
    } catch {}
    if (typeof window !== 'undefined') {
      localStorage.removeItem(LOCAL_AUTH_KEY);
      localStorage.removeItem("redo_demo_role");
    }
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
      <div className="animate-pulse text-slate-700 text-xs font-black flex items-center gap-2">
        <span className="w-3.5 h-3.5 rounded-full bg-[#FFC800]"></span> Loading REDO...
      </div>
    </div>
  );
}

export function Protected({ children }: { children: ReactNode }) {
  const { loading, session, profile } = useAuth();
  const location = useLocation();

  if (loading) return <FullPageSpinner />;
  // Authenticated if valid Supabase session OR local authenticated profile exists
  if (!session && !profile) {
    return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  }
  return <>{children}</>;
}
