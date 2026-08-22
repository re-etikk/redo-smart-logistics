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

const getDevProfile = (pathname: string): Profile => {
  const isOwnerPath =
    pathname.startsWith('/owner') ||
    pathname.includes('/truck') ||
    pathname.includes('/earning') ||
    pathname.includes('/trip') ||
    pathname.includes('/payment') ||
    pathname.includes('/review');

  const role: Role = isOwnerPath ? 'truck_owner' : 'sme';
  return {
    id: "localhost-dev-user",
    role,
    full_name: isOwnerPath ? "Rohit Sharma (Dev Truck Owner)" : "Ritik (Dev Customer)",
    company_name: isOwnerPath ? "Rohit Logistics Fleet" : "Ritik Freight Ltd",
    phone: "+91 9876543210",
    onboarding_complete: true,
  };
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

  const loadProfile = useCallback(async (s: Session | null) => {
    if (!s) {
      const isLocalhost = typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1');
      if (isLocalhost) {
        const p = getDevProfile(window.location.pathname);
        setProfile(p);
        return p;
      }
      setProfile(null);
      return null;
    }
    try {
      let { data } = await supabase.from('profiles').select('*').eq('id', s.user.id).single();
      if (!data) {
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
      const meta = s.user.user_metadata || {};
      const fallback: Profile = {
        id: s.user.id,
        role: (meta.role as Role) || 'sme',
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
    const isHashAuth =
      window.location.hash.includes("access_token") ||
      window.location.hash.includes("refresh_token") ||
      window.location.href.includes("code=");

    const handleSession = async (s: Session | null) => {
      setSession(s);
      if (s) {
        await loadProfile(s);
        if (window.location.hash.includes("access_token")) {
          window.history.replaceState(null, "", window.location.pathname);
        }
      } else {
        const isLocalhost = typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1');
        if (isLocalhost) {
          setProfile(getDevProfile(window.location.pathname));
        } else {
          setProfile(null);
        }
      }
      setLoading(false);
    };

    supabase.auth.getSession().then(({ data }) => {
      if (data.session) {
        handleSession(data.session);
      } else if (!isHashAuth) {
        handleSession(null);
      }
    });

    const { data: sub } = supabase.auth.onAuthStateChange((_evt, s) => {
      handleSession(s);
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
      <div className="animate-pulse text-slate-700 text-xs font-black flex items-center gap-2">
        <span className="w-3.5 h-3.5 rounded-full bg-[#FFC800]"></span> Authenticating Redo Partner...
      </div>
    </div>
  );
}

export function Protected({ role, children, allowIncompleteOnboarding = false }: {
  role?: Role; children: ReactNode; allowIncompleteOnboarding?: boolean;
}) {
  const { loading, session, profile } = useAuth();
  const location = useLocation();
  const isLocalhost = typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1');

  if (loading) return <FullPageSpinner />;

  // AUTOMATIC BYPASS ON LOCALHOST FOR DEVELOPMENT
  if (!session && isLocalhost) {
    return <>{children}</>;
  }

  if (!session) return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  if (!profile && !isLocalhost) return <Navigate to="/signup" replace />;
  if (profile && !profile.onboarding_complete && !allowIncompleteOnboarding && !isLocalhost) {
    return <Navigate to={profile.role === 'sme' ? '/onboarding/sme' : '/onboarding/owner'} replace />;
  }
  if (profile && role && profile.role !== role && !isLocalhost) {
    return <Navigate to={profile.role === 'sme' ? '/dashboard/sme' : '/dashboard/owner'} replace />;
  }
  return <>{children}</>;
}
