import { useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { supabase } from "../../lib/supabase";
import { Logo } from "../../components/Layout";
import { Button } from "../../components/ui";
import { KeyRound, ArrowRight, CheckCircle2, ArrowLeft } from "lucide-react";

export default function Forgot() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      const { error: err } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: window.location.origin + "/login",
      });
      if (err) throw err;
      setSent(true);
    } catch (err: any) {
      // Show graceful feedback
      setSent(true);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col justify-between text-slate-100 selection:bg-blue-600 selection:text-white">
      {/* Header */}
      <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-md sticky top-0 z-50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 h-16 flex items-center justify-between">
          <Link to="/">
            <Logo dark />
          </Link>
          <Link to="/login">
            <Button variant="secondary" className="!bg-slate-800 !text-slate-200 !border-slate-700 hover:!bg-slate-700 !text-xs !py-1.5 flex items-center gap-1">
              <ArrowLeft className="w-3.5 h-3.5" />
              <span>Back to Sign In</span>
            </Button>
          </Link>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 py-12 grid place-items-center">
        <div className="w-full max-w-md mx-auto">
          <div className="bg-slate-900/90 border border-slate-800 rounded-3xl p-6 sm:p-8 shadow-2xl backdrop-blur-xl space-y-6 relative overflow-hidden">
            {/* Ambient Glow */}
            <div className="absolute -top-24 -right-24 w-48 h-48 bg-blue-600/15 rounded-full blur-3xl pointer-events-none" />

            <div className="w-12 h-12 rounded-2xl bg-blue-500/10 border border-blue-500/20 text-blue-400 flex items-center justify-center">
              <KeyRound className="w-6 h-6" />
            </div>

            <div>
              <h1 className="text-2xl font-bold text-white tracking-tight">Reset Your Password</h1>
              <p className="text-xs text-slate-400 mt-1">Enter your registered email address to receive password recovery instructions.</p>
            </div>

            {sent ? (
              <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-medium space-y-2">
                <div className="flex items-center gap-2 font-bold text-sm text-emerald-300">
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Reset Link Sent</span>
                </div>
                <p className="leading-relaxed">
                  If an account exists for <span className="font-semibold text-white">{email}</span>, a password reset link has been dispatched to your inbox.
                </p>
              </div>
            ) : (
              <form onSubmit={submit} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5">Email address</label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="name@business.com"
                    className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                  />
                </div>

                {error && (
                  <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs font-medium">
                    {error}
                  </div>
                )}

                <Button
                  type="submit"
                  disabled={busy}
                  className="w-full !bg-blue-600 hover:!bg-blue-500 !text-white !py-2.5 !rounded-xl !font-bold shadow-lg shadow-blue-600/20"
                >
                  {busy ? "Sending Link…" : "Send Reset Link"}
                  {!busy && <ArrowRight className="w-4 h-4 ml-1" />}
                </Button>
              </form>
            )}

            <div className="pt-2 text-center">
              <Link to="/login" className="text-xs font-semibold text-slate-400 hover:text-white transition inline-flex items-center gap-1">
                <ArrowLeft className="w-3.5 h-3.5" />
                <span>Return to Sign In</span>
              </Link>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-800/60 bg-slate-950 py-4">
        <div className="max-w-7xl mx-auto px-4 text-center text-xs text-slate-500">
          REDO Commercial Smart Backhaul Platform · Match. Consolidate. Track. Optimize.
        </div>
      </footer>
    </div>
  );
}

