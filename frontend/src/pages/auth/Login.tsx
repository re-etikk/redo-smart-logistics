import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { Button, Card, Field, inputCls } from '../../components/ui';
import { ShieldCheck, Zap, Lock, Mail, ArrowRight } from 'lucide-react';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const { refreshProfile, loginAsDemoAdmin } = useAuth();

  const handleDemoAccess = () => {
    loginAsDemoAdmin();
    navigate('/admin');
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true); setError('');
    const { error: err } = await supabase.auth.signInWithPassword({ email, password });
    if (err) {
      setError(err.message || 'Incorrect email or password.');
      setBusy(false);
      return;
    }
    await refreshProfile();
    navigate('/admin');
  };

  return (
    <div className="min-h-screen bg-slate-950 text-white flex flex-col justify-center items-center px-4 py-12 relative overflow-hidden">
      {/* Subtle Background Glow */}
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
            Highway Corridor Matching, Fleet Radar & Dynamic Pricing Desk
          </p>
        </div>

        {/* 1-Tap Quick Executive Access Card */}
        <Card className="p-6 bg-slate-900/90 border border-amber-500/30 rounded-2xl shadow-xl shadow-amber-500/5 mb-6 backdrop-blur-xl">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-9 h-9 rounded-xl bg-amber-500/20 border border-amber-500/40 flex items-center justify-center text-amber-400">
              <Zap size={20} />
            </div>
            <div>
              <h2 className="text-sm font-bold text-white">1-Tap Executive Access</h2>
              <p className="text-[11px] text-slate-400">Instant access for system evaluation & operations</p>
            </div>
          </div>
          <Button
            onClick={handleDemoAccess}
            className="w-full bg-gradient-to-r from-amber-400 to-amber-500 hover:from-amber-500 hover:to-amber-600 text-slate-950 font-black py-3 rounded-xl flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20"
          >
            <span>Enter Operations Control Room</span>
            <ArrowRight size={16} />
          </Button>
        </Card>

        {/* Or Authenticate with Credentials */}
        <div className="relative flex py-2 items-center mb-6">
          <div className="flex-grow border-t border-slate-800"></div>
          <span className="flex-shrink mx-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Or Login with Credentials</span>
          <div className="flex-grow border-t border-slate-800"></div>
        </div>

        <Card className="p-6 bg-slate-900/80 border border-slate-800 rounded-2xl shadow-xl backdrop-blur-xl">
          <form onSubmit={submit} className="space-y-4">
            {error && (
              <div className="p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs font-medium">
                {error}
              </div>
            )}

            <Field label="Admin Email">
              <div className="relative">
                <Mail size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@redologistics.in"
                  className={inputCls + " pl-10 bg-slate-950 border-slate-800 text-white placeholder:text-slate-600"}
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
                  placeholder="••••••••"
                  className={inputCls + " pl-10 bg-slate-950 border-slate-800 text-white placeholder:text-slate-600"}
                />
              </div>
            </Field>

            <Button
              type="submit"
              disabled={busy}
              className="w-full bg-slate-800 hover:bg-slate-700 text-white font-bold py-2.5 rounded-xl border border-slate-700"
            >
              {busy ? "Authenticating…" : "Sign In to Operations"}
            </Button>
          </form>
        </Card>

        {/* Portals Footnote */}
        <div className="mt-8 text-center text-xs text-slate-500 space-y-1">
          <p>REDO Transport & Logistics Marketplace</p>
          <div className="flex justify-center gap-4 text-slate-400 pt-1">
            <span className="hover:text-amber-400 cursor-pointer">Customer Web: frontend-customer</span>
            <span>•</span>
            <span className="hover:text-amber-400 cursor-pointer">Partner Web: frontend-owner</span>
          </div>
        </div>
      </div>
    </div>
  );
}
