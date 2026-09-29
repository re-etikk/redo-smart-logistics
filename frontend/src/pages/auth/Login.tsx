import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { Button, Card, Field, inputCls } from '../../components/ui';
import { ShieldCheck, Lock, Mail, ArrowRight, AlertCircle, KeyRound } from 'lucide-react';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const { refreshProfile } = useAuth();

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError('');

    const { error: err } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    if (err) {
      setError(err.message || 'Incorrect email or password. Please verify your credentials.');
      setBusy(false);
      return;
    }

    await refreshProfile();
    navigate('/admin');
  };

  return (
    <div className="min-h-screen bg-slate-950 text-white flex flex-col justify-center items-center px-4 py-12 relative overflow-hidden">
      {/* Background Ambience */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md relative z-10">
        {/* Header Branding */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 text-xs font-bold tracking-wide uppercase mb-4">
            <ShieldCheck size={14} />
            REDO Operations Command Center
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-white">
            Admin Control Room
          </h1>
          <p className="text-xs sm:text-sm text-slate-400 mt-2">
            Corridor Fleet Radar, Live Shipments, Dynamic Pricing & KYC Desk
          </p>
        </div>

        {/* Security Notice */}
        <div className="mb-6 p-3 rounded-xl bg-slate-900 border border-slate-800 text-[11px] text-slate-400 flex items-start gap-2.5">
          <KeyRound size={16} className="text-amber-400 shrink-0 mt-0.5" />
          <span>
            Strict role-based access control enabled. Only accounts with verified <strong className="text-amber-400">admin</strong> role can access operations data.
          </span>
        </div>

        {/* Admin Login Card */}
        <Card className="p-6 bg-slate-900/90 border border-slate-800 rounded-2xl shadow-2xl backdrop-blur-xl">
          <form onSubmit={submit} className="space-y-4">
            {error && (
              <div className="p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs font-medium flex items-start gap-2">
                <AlertCircle size={16} className="shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <Field label="Administrator Email">
              <div className="relative">
                <Mail size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@redologistics.in"
                  className={inputCls + " pl-10 bg-slate-950 border-slate-800 text-white placeholder:text-slate-600 focus:border-amber-400"}
                />
              </div>
            </Field>

            <Field label="Password">
              <div className="relative">
                <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className={inputCls + " pl-10 bg-slate-950 border-slate-800 text-white placeholder:text-slate-600 focus:border-amber-400"}
                />
              </div>
            </Field>

            <div className="-mt-2 text-right">
              <Link to="/forgot-password" className="text-xs font-semibold text-amber-400 hover:text-amber-300">
                Forgot password?
              </Link>
            </div>

            <Button
              type="submit"
              disabled={busy}
              className="w-full bg-amber-400 hover:bg-amber-500 text-slate-950 font-black py-3 rounded-xl flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 transition-all"
            >
              <span>{busy ? "Verifying Credentials…" : "Authenticate & Enter Control Room"}</span>
              <ArrowRight size={16} />
            </Button>
          </form>
        </Card>

        {/* Portals Footnote */}
        <div className="mt-8 text-center text-xs text-slate-500 space-y-1">
          <p className="font-semibold text-slate-400">REDO Transport & Logistics Network</p>
          <p className="text-[11px]">Partner & Customer portals operate as independent applications.</p>
        </div>
      </div>
    </div>
  );
}
