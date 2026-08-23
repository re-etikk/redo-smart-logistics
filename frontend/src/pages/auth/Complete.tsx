// Finishes account setup for sessions that have no profile row yet:
// Google OAuth sign-ins and email signups confirmed via the email link.
import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { api } from '../../services/api';
import { useAuth } from '../../hooks/useAuth';
import { clearPendingProfile, readPendingProfile } from '../../lib/authHelpers';
import { Logo } from '../../components/Layout';
import { Button, Card } from '../../components/ui';
import type { Role } from '../../lib/types';

export default function CompleteAccount() {
  const { loading, session, profile, refreshProfile } = useAuth();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const pending = readPendingProfile();

  // Already fully set up (or not signed in) → route away.
  useEffect(() => {
    if (loading) return;
    if (!session) { navigate('/login', { replace: true }); return; }
    if (profile) {
      clearPendingProfile();
      navigate(profile.onboarding_complete
        ? (profile.role === 'sme' ? '/dashboard/sme' : profile.role === 'admin' ? '/admin' : '/dashboard/owner')
        : (profile.role === 'sme' ? '/onboarding/sme' : '/onboarding/owner'), { replace: true });
    }
  }, [loading, session, profile, navigate]);

  const choose = async (role: Role) => {
    setBusy(true); setError('');
    try {
      const meta = session?.user.user_metadata ?? {};
      await api.post('/auth/profile', {
        role,
        full_name: pending.full_name || meta.full_name || meta.name || session?.user.email?.split('@')[0],
        phone: pending.phone || null,
      });
      clearPendingProfile();
      await refreshProfile();
      navigate(role === 'sme' ? '/onboarding/sme' : '/onboarding/owner', { replace: true });
    } catch (e: any) { setError(e.message); setBusy(false); }
  };

  // Pending role saved before the redirect (from SignUp) → finish silently.
  useEffect(() => {
    if (!loading && session && !profile && pending.role && !busy) choose(pending.role);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [loading, session, profile]);

  return (
    <div className="min-h-screen bg-canvas flex flex-col">
      <header className="bg-white border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center"><Link to="/"><Logo /></Link></div>
      </header>
      <main className="flex-1 grid place-items-center px-4 py-10">
        <div className="w-full max-w-2xl">
          <h1 className="text-2xl font-extrabold text-ink text-center">
            {pending.role ? 'Finishing your account…' : 'One last step — how will you use Redo?'}
          </h1>
          {error && <p className="mt-3 text-center text-sm font-medium text-danger">{error}</p>}
          {!pending.role && (
            <div className="mt-8 grid sm:grid-cols-2 gap-4">
              <Card hover className="p-6">
                <h2 className="font-bold text-ink">I have a truck</h2>
                <p className="mt-1 text-sm text-ink-soft">Earn from unused return capacity.</p>
                <Button className="mt-5 w-full" disabled={busy} onClick={() => choose('truck_owner')}>Continue as truck owner</Button>
              </Card>
              <Card hover className="p-6">
                <h2 className="font-bold text-ink">I have cargo</h2>
                <p className="mt-1 text-sm text-ink-soft">Ship partial loads affordably.</p>
                <Button className="mt-5 w-full" disabled={busy} onClick={() => choose('sme')}>Continue as shipper</Button>
              </Card>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
