import { useState, type ChangeEvent, type FormEvent } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { api } from '../../services/api';
import { useAuth } from '../../hooks/useAuth';
import { GoogleIcon, savePendingProfile, signInWithGoogle } from '../../lib/authHelpers';
import { Logo } from '../../components/Layout';
import { Button, Card, Field, inputCls, useToast } from '../../components/ui';
import type { Role } from '../../lib/types';

export default function SignUp() {
  const [params] = useSearchParams();
  const [role, setRole] = useState<Role | null>((params.get('role') as Role) || null);
  const [form, setForm] = useState({ full_name: '', email: '', password: '', phone: '' });
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [awaitingConfirm, setAwaitingConfirm] = useState(false);
  const navigate = useNavigate();
  const { refreshProfile } = useAuth();
  const toast = useToast();
  const set = (k: string) => (e: ChangeEvent<HTMLInputElement>) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!role) return;
    setBusy(true); setError('');
    const { data, error: err } = await supabase.auth.signUp({
      email: form.email, password: form.password,
      options: { data: { full_name: form.full_name } },
    });
    if (err) { setError(err.message); setBusy(false); return; }

    if (!data.session) {
      // Email confirmation is ON in Supabase: no session until the link is clicked.
      // Stash the intended role — /auth/complete finishes the profile after first sign-in.
      savePendingProfile({ role, full_name: form.full_name, phone: form.phone });
      setAwaitingConfirm(true); setBusy(false);
      return;
    }

    try {
      await api.post('/auth/profile', { full_name: form.full_name, phone: form.phone, role });
    } catch (e2: any) { setError(e2.message); setBusy(false); return; }
    await refreshProfile();
    navigate(role === 'sme' ? '/onboarding/sme' : '/onboarding/owner');
  };

  const google = async () => {
    try { await signInWithGoogle(role ? { role } : undefined); }
    catch (e: any) { setError(e.message); }
  };

  const resend = async () => {
    const { error: err } = await supabase.auth.resend({ type: 'signup', email: form.email });
    if (err) setError(err.message); else toast('Confirmation email sent again.');
  };

  if (awaitingConfirm) {
    return (
      <Shell>
        <Card className="w-full max-w-sm p-6 text-center">
          <h1 className="text-xl font-extrabold text-ink">Confirm your email</h1>
          <p className="mt-2 text-sm text-ink-soft">
            We sent a confirmation link to <span className="font-semibold">{form.email}</span>.
            Click it, then sign in — we will finish setting up your {role === 'sme' ? 'shipper' : 'truck owner'} account automatically.
          </p>
          {error && <p className="mt-2 text-sm font-medium text-danger">{error}</p>}
          <Button className="mt-4 w-full" onClick={() => navigate('/login')}>Go to sign in</Button>
          <button onClick={resend} className="mt-3 text-sm font-semibold text-accent">Resend email</button>
          <p className="mt-4 text-xs text-ink-faint">
            No email? Ask your admin to disable “Confirm email” in Supabase Auth for demo runs, or configure SMTP.
          </p>
        </Card>
      </Shell>
    );
  }

  return (
    <Shell>
      {!role ? (
        <div className="w-full max-w-2xl">
          <h1 className="text-2xl font-extrabold text-ink text-center">How will you use Redo?</h1>
          <div className="mt-8 grid sm:grid-cols-2 gap-4">
            <Card hover className="p-6">
              <h2 className="font-bold text-ink">I have a truck</h2>
              <p className="mt-1 text-sm text-ink-soft">Earn from unused return capacity.</p>
              <Button className="mt-5 w-full" onClick={() => setRole('truck_owner')}>Continue as truck owner</Button>
            </Card>
            <Card hover className="p-6">
              <h2 className="font-bold text-ink">I have cargo</h2>
              <p className="mt-1 text-sm text-ink-soft">Ship partial loads affordably.</p>
              <Button className="mt-5 w-full" onClick={() => setRole('sme')}>Continue as shipper</Button>
            </Card>
          </div>
        </div>
      ) : (
        <Card className="w-full max-w-sm p-6">
          <h1 className="text-xl font-extrabold text-ink">Create account</h1>
          <p className="text-sm text-ink-faint mt-0.5">{role === 'sme' ? 'SME / Shipper' : 'Truck owner'} ·{' '}
            <button className="text-accent font-semibold" onClick={() => setRole(null)}>change</button></p>
          <form className="mt-5 space-y-4" onSubmit={submit}>
            <Field label="Full name"><input required className={inputCls} value={form.full_name} onChange={set('full_name')} /></Field>
            <Field label="Email"><input type="email" required className={inputCls} value={form.email} onChange={set('email')} /></Field>
            <Field label="Phone"><input type="tel" required className={inputCls} value={form.phone} onChange={set('phone')} /></Field>
            <Field label="Password" error={error}>
              <input type="password" required minLength={8} className={inputCls} value={form.password} onChange={set('password')} />
            </Field>
            <Button className="w-full" disabled={busy}>{busy ? 'Creating account…' : 'Create account'}</Button>
          </form>
          <div className="my-4 flex items-center gap-3 text-xs text-ink-faint">
            <span className="h-px flex-1 bg-line" />or<span className="h-px flex-1 bg-line" />
          </div>
          <button type="button" onClick={google}
            className="w-full inline-flex items-center justify-center gap-2 rounded-lg border border-line bg-white px-4 py-2.5 text-sm font-semibold text-ink hover:bg-canvas transition">
            <GoogleIcon /> Sign up with Google
          </button>
          <p className="mt-4 text-sm text-ink-faint">Already have an account?{' '}
            <Link to="/login" className="font-semibold text-accent">Sign in</Link></p>
        </Card>
      )}
    </Shell>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-canvas flex flex-col">
      <header className="bg-white border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Link to="/" className="text-xs font-bold text-ink-muted hover:text-ink bg-slate-100 hover:bg-slate-200 px-3 py-1.5 rounded-lg transition">
              ← Back to Home
            </Link>
            <Link to="/"><Logo /></Link>
          </div>
          <Link to="/login" className="text-xs font-semibold text-accent hover:underline">
            Sign in →
          </Link>
        </div>
      </header>
      <main className="flex-1 grid place-items-center px-4 py-10">{children}</main>
    </div>
  );
}
