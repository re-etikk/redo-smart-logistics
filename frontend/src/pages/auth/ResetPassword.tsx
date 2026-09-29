import { useEffect, useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { Button, Card, Field, inputCls } from '../../components/ui';
import { Lock, ShieldCheck } from 'lucide-react';

export default function ResetPassword() {
  const [checkingSession, setCheckingSession] = useState(true);
  const [hasRecoverySession, setHasRecoverySession] = useState(false);
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const { refreshProfile } = useAuth();

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setHasRecoverySession(Boolean(data.session));
      setCheckingSession(false);
    });

    const { data } = supabase.auth.onAuthStateChange((_event, session) => {
      setHasRecoverySession(Boolean(session));
      setCheckingSession(false);
    });

    return () => data.subscription.unsubscribe();
  }, []);

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setError('');
    if (password.length < 8) {
      setError('Use a password with at least 8 characters.');
      return;
    }
    if (password !== confirmPassword) {
      setError('The passwords do not match.');
      return;
    }

    setBusy(true);
    const { error: updateError } = await supabase.auth.updateUser({ password });
    if (updateError) {
      setError(updateError.message);
      setBusy(false);
      return;
    }

    await refreshProfile();
    navigate('/admin', { replace: true });
  };

  return (
    <div className="min-h-screen bg-slate-950 text-white grid place-items-center px-4 py-12">
      <div className="w-full max-w-md">
        <div className="text-center mb-7">
          <div className="inline-flex items-center gap-2 text-amber-400 text-xs font-bold uppercase mb-4">
            <ShieldCheck size={15} /> REDO Operations Command Center
          </div>
          <h1 className="text-2xl font-black">Set a new password</h1>
        </div>

        <Card className="p-6 bg-slate-900 border border-slate-800 rounded-2xl">
          {checkingSession ? (
            <p className="text-sm text-slate-300">Verifying password reset link…</p>
          ) : !hasRecoverySession ? (
            <div className="space-y-4">
              <p className="text-sm text-slate-300">This reset link is invalid or expired. Request a fresh link to continue.</p>
              <Link to="/forgot-password" className="text-sm font-semibold text-amber-400 hover:text-amber-300">
                Request another reset link
              </Link>
            </div>
          ) : (
            <form onSubmit={submit} className="space-y-4">
              {error && <p role="alert" className="text-sm text-rose-400">{error}</p>}
              <Field label="New password">
                <div className="relative">
                  <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                  <input
                    type="password"
                    required
                    minLength={8}
                    autoComplete="new-password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    className={`${inputCls} pl-10 bg-slate-950 border-slate-800 text-white`}
                  />
                </div>
              </Field>
              <Field label="Confirm new password">
                <div className="relative">
                  <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                  <input
                    type="password"
                    required
                    minLength={8}
                    autoComplete="new-password"
                    value={confirmPassword}
                    onChange={(event) => setConfirmPassword(event.target.value)}
                    className={`${inputCls} pl-10 bg-slate-950 border-slate-800 text-white`}
                  />
                </div>
              </Field>
              <Button type="submit" disabled={busy} className="w-full bg-amber-400 text-slate-950 font-black">
                {busy ? 'Updating password…' : 'Update password'}
              </Button>
            </form>
          )}
        </Card>

        <p className="mt-5 text-center text-sm">
          <Link to="/login" className="font-semibold text-amber-400 hover:text-amber-300">Back to admin login</Link>
        </p>
      </div>
    </div>
  );
}