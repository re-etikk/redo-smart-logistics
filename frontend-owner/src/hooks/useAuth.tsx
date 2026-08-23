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

const devProfile: Profile = {
  id: "localhost-dev-owner",
  role: "truck_owner",
  full_name: "Rohit Sharma (Dev)",
  company_name: "Rohit Logistics Fleet",
  phone: "+91 9876543210",
  onboarding_complete: true,
};

const AuthCtx = createContext<AuthState>({
  loading: true, session: null, profile: null,
  refreshProfile: async () => {}, signOut: async () => {},
});

export const useAuth = () => useContext(AuthCtx);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [loading, setLoading] = useState(true);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);

  const isLocalhost = typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1');

  const loadProfile = useCallback(async (s: Session | null) => {
    if (!s) {
      if (isLocalhost) { setProfile(devProfile); return devProfile; }
      setProfile(null);
      return null;
    }
    try {
      let { data } = await supabase.from('profiles').select('*').eq('id', s.user.id).single();
      if (!data) {
        const meta = s.user.user_metadata || {};
        const newProfile: Profile = {
          id: s.user.id,
          role: 'truck_owner',
          full_name: meta.full_name || meta.name || s.user.email?.split('@')[0] || 'REDO Owner',
          company_name: meta.company_name || 'REDO Fleet',
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
        role: 'truck_owner',
        full_name: meta.full_name || s.user.email?.split('@')[0] || 'REDO Owner',
        company_name: 'REDO Fleet',
        phone: '+91 9876543210',
        onboarding_complete: true,
      };
      setProfile(fallback);
      return fallback;
    }
  }, [isLocalhost]);

  useEffect(() => {
    const handleSession = async (s: Session | null) => {
      setSession(s);
      if (s) {
        await loadProfile(s);
        if (window.location.hash.includes("access_token")) {
          window.history.replaceState(null, "", window.location.pathname);
        }
      } else {
        if (isLocalhost) setProfile(devProfile);
        else setProfile(null);
      }
      setLoading(false);
    };

    supabase.auth.getSession().then(({ data }: { data: { session: Session | null } }) => {
      handleSession(data.session);
    });

    const { data: sub } = supabase.auth.onAuthStateChange((_evt: AuthChangeEvent, s: Session | null) => {
      handleSession(s);
    });
    return () => sub.subscription.unsubscribe();
  }, [loadProfile, isLocalhost]);

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
      <div className="animate-pulse text-slate-700 text-xs font-black flex items-center gap-2">
        <span className="w-3.5 h-3.5 rounded-full bg-[#FFC800]"></span> Loading REDO Owner...
      </div>
    </div>
  );
}

export function Protected({ children }: { children: ReactNode }) {
  const { loading, session } = useAuth();
  const location = useLocation();
  const isLocalhost = typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1');

  if (loading) return <FullPageSpinner />;
  if (!session && isLocalhost) return <>{children}</>;
  if (!session) return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  return <>{children}</>;
}
