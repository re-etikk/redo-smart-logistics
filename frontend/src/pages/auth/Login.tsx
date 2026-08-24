import { useState, type FormEvent } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { GoogleIcon, signInWithGoogle } from '../../lib/authHelpers';
import { Logo } from '../../components/Layout';
import { Button, Card, Field, inputCls, useToast } from '../../components/ui';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [unconfirmed, setUnconfirmed] = useState(false);
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const location = useLocation() as any;
  const { refreshProfile } = useAuth();
  const toast = useToast();

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true); setError(''); setUnconfirmed(false);
    const { error: err } = await supabase.auth.signInWithPassword({ email, password });
    if (err) {
      // Surface the REAL reason — "Email not confirmed" is not a wrong password.
      const msg = err.message.toLowerCase();
      if (msg.includes('confirm')) {
        setUnconfirmed(true);
        setError('Your email is not confirmed yet. Check your inbox, or resend the link below.');
      } else if (msg.includes('invalid')) {
        setError('Incorrect email or password.');
      } else {
        setError(err.message);
      }
      setBusy(false); return;
    }
    await refreshProfile();
    const { data } = await supabase.auth.getSession();
    const uid = data.session?.user.id;
    const { data: profile } = await supabase.from('profiles').select('role, onboarding_complete').eq('id', uid).single();
    if (!profile) navigate('/auth/complete');
    else if (!profile.onboarding_complete) navigate(profile.role === 'sme' ? '/onboarding/sme' : '/onboarding/owner');
    else navigate(location.state?.from || (profile.role === 'sme' ? '/dashboard/sme' : profile.role === 'admin' ? '/admin' : '/dashboard/owner'));
  };

  const resend = async () => {
    const { error: err } = await supabase.auth.resend({ type: 'signup', email });
    if (err) setError(err.message);
    else { toast('Confirmation email sent — check your inbox.'); setUnconfirmed(false); }
  };

  const google = async () => {
    try { await signInWithGoogle(); } catch (e: any) { setError(e.message); }
  };

  return (
    <div className="min-h-screen bg-canvas flex flex-col">
      <header className="bg-white border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center"><Link to="/"><Logo /></Link></div>
      </header>
      <main className="flex-1 grid place-items-center px-4 py-10">
        <Card className="w-full max-w-sm p-6">
          <h1 className="text-xl font-extrabold text-ink">Sign in</h1>
          <form className="mt-5 space-y-4" onSubmit={submit}>
            <Field label="Email">
              <input type="email" required className={inputCls} value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" />
            </Field>
            <Field label="Password" error={error}>
              <input type="password" required className={inputCls} value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
            </Field>
            {unconfirmed && (
              <button type="button" onClick={resend} className="text-sm font-semibold text-accent">
                Resend confirmation email →
              </button>
            )}
            <Button className="w-full" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</Button>
          </form>

          <div className="my-4 flex items-center gap-3 text-xs text-ink-faint">
            <span className="h-px flex-1 bg-line" />or<span className="h-px flex-1 bg-line" />
          </div>
          <button type="button" onClick={google}
            className="w-full inline-flex items-center justify-center gap-2 rounded-lg border border-line bg-white px-4 py-2.5 text-sm font-semibold text-ink hover:bg-canvas transition">
            <GoogleIcon /> Continue with Google
          </button>

          <div className="mt-4 flex justify-between text-sm">
            <Link to="/forgot-password" className="font-semibold text-accent">Forgot password</Link>
            <Link to="/signup" className="font-semibold text-accent">Create account</Link>
          </div>
          <p className="mt-5 text-xs text-ink-faint border-t border-line pt-4">
            Demo accounts (real authenticated sessions): <span className="font-semibold">demo.owner@redo.app</span> and{' '}
            <span className="font-semibold">demo.sme@redo.app</span> — password set by your event organiser.
          </p>
        </Card>
      </main>
    </div>
  );
}
