import {
  createContext, useCallback, useContext, useEffect, useState, type ReactNode,
} from 'react';
import { Navigate } from 'react-router-dom';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import type { Profile, Role } from '../lib/types';
import { ShieldAlert, LogOut, RefreshCw, Lock, CheckCircle2 } from 'lucide-react';
import { Button, Card } from '../components/ui';

interface AuthState {
  loading: boolean;
  session: Session | null;
  profile: Profile | null;
  isAdmin: boolean;
  refreshProfile: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthCtx = createContext<AuthState>({
  loading: true,
  session: null,
  profile: null,
  isAdmin: false,
  refreshProfile: async () => {},
  signOut: async () => {},
});

export const useAuth = () => useContext(AuthCtx);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [loading, setLoading] = useState(true);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);

  const loadProfile = useCallback(async (s: Session | null) => {
    setProfile(null);
    if (!s || !s.user) {
      return;
    }

    try {
      const { data } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', s.user.id)
        .maybeSingle();

      if (data) {
        setProfile(data as Profile);
      } else {
        // Missing profile rows never inherit a role from user-editable metadata.
        setProfile({
          id: s.user.id,
          full_name: s.user.user_metadata?.full_name || s.user.email?.split('@')[0] || 'User',
          role: 'sme' as Role,
          phone: s.user.phone || s.user.user_metadata?.phone || null,
          company_name: s.user.user_metadata?.company_name || null,
          avatar_url: '',
          onboarding_complete: false,
        });
      }
    } catch (err) {
      console.error('Failed to load user profile:', err);
      setProfile(null);
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
      setLoading(false);
    });

    return () => sub.subscription.unsubscribe();
  }, [loadProfile]);

  const refreshProfile = useCallback(async () => {
    setLoading(true);
    const { data } = await supabase.auth.getSession();
    setSession(data.session);
    await loadProfile(data.session);
    setLoading(false);
  }, [loadProfile]);

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    setProfile(null);
    setSession(null);
  }, []);

  const isAdmin = profile?.role === 'admin' && profile.status !== 'suspended';

  return (
    <AuthCtx.Provider value={{ loading, session, profile, isAdmin, refreshProfile, signOut }}>
      {children}
    </AuthCtx.Provider>
  );
}

function FullPageSpinner() {
  return (
    <div className="min-h-screen grid place-items-center bg-slate-950">
      <div className="text-amber-400 text-sm font-bold flex items-center gap-3">
        <span className="w-3 h-3 rounded-full bg-amber-400 animate-ping" />
        <span>Verifying Security Clearance & Session…</span>
      </div>
    </div>
  );
}

function AdminApprovalPending() {
  const { session, profile, refreshProfile, signOut, loading } = useAuth();

  return (
    <div className="min-h-screen bg-slate-950 text-white flex flex-col justify-center items-center px-4 py-12 relative overflow-hidden">
      {/* Background Ambience */}
      <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-rose-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-lg relative z-10">
        <div className="text-center mb-6">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-rose-500/15 border border-rose-500/30 text-rose-400 text-xs font-bold uppercase tracking-wider mb-4">
            <Lock size={14} />
            Security Clearance Restricted
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-white">
            Administrator Approval Required
          </h1>
          <p className="text-xs sm:text-sm text-slate-400 mt-2">
            This account does not have authorization to access the REDO Operations Control Room.
          </p>
        </div>

        <Card className="p-6 bg-slate-900/90 border border-slate-800 rounded-2xl shadow-2xl backdrop-blur-xl">
          {/* User Identity Details */}
          <div className="p-4 rounded-xl bg-slate-950 border border-slate-800/80 mb-5 space-y-2 text-xs">
            <div className="flex justify-between items-center text-slate-400">
              <span>Account Name</span>
              <span className="font-bold text-white">{profile?.full_name || 'REDO User'}</span>
            </div>
            <div className="flex justify-between items-center text-slate-400">
              <span>Email</span>
              <span className="font-mono text-slate-300">{session?.user.email || '—'}</span>
            </div>
            <div className="flex justify-between items-center text-slate-400">
              <span>Assigned Role</span>
              <span className="px-2 py-0.5 rounded bg-slate-800 text-amber-300 font-bold uppercase text-[10px]">
                {profile?.role === 'sme' ? 'Shipper (Customer)' : profile?.role === 'truck_owner' ? 'Truck Partner' : profile?.role || 'Guest'}
              </span>
            </div>
            <div className="flex justify-between items-center text-slate-400">
              <span>Approval Status</span>
              <span className="px-2 py-0.5 rounded bg-rose-500/20 text-rose-400 font-bold text-[10px]">
                {profile?.status === 'suspended' ? 'Account Suspended' : 'Pending Admin Approval'}
              </span>
            </div>
          </div>

          <div className="p-3.5 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-300 text-xs mb-6 flex items-start gap-3">
            <ShieldAlert size={18} className="shrink-0 mt-0.5 text-amber-400" />
            <div className="space-y-1">
              <p className="font-bold text-amber-200">How to activate admin access:</p>
              <p className="text-slate-300 text-[11px] leading-relaxed">
                Contact the Super Administrator or run the approval command in the database to promote this email to <code className="bg-slate-900 px-1 py-0.5 rounded text-amber-400 font-bold">admin</code>. Once approved, click "Check Approval Status" below.
              </p>
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-3">
            <Button
              onClick={() => refreshProfile()}
              disabled={loading}
              className="flex-1 bg-amber-400 hover:bg-amber-500 text-slate-950 font-bold py-2.5 rounded-xl flex items-center justify-center gap-2"
            >
              <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
              <span>{loading ? "Checking…" : "Check Approval Status"}</span>
            </Button>
            <Button
              onClick={() => signOut()}
              variant="secondary"
              className="bg-slate-800 hover:bg-slate-700 text-white font-semibold py-2.5 rounded-xl border border-slate-700 flex items-center justify-center gap-2"
            >
              <LogOut size={14} />
              <span>Sign Out</span>
            </Button>
          </div>
        </Card>
      </div>
    </div>
  );
}

export function Protected({ children }: { role?: Role; children: ReactNode; allowIncompleteOnboarding?: boolean }) {
  const { loading, session, profile, isAdmin } = useAuth();

  if (loading) return <FullPageSpinner />;

  // 1. Must be logged in via Supabase
  if (!session) {
    return <Navigate to="/login" replace />;
  }

  // 2. Missing profiles and non-admin roles remain blocked pending approval.
  if (!profile || !isAdmin) {
    return <AdminApprovalPending />;
  }

  return <>{children}</>;
}
