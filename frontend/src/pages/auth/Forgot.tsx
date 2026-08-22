import { useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { supabase } from "../../lib/supabase";
import { Logo } from "../../components/Layout";
import { Mail, ShieldCheck, Tag, Headset, ArrowLeft } from "lucide-react";

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
        redirectTo: `${window.location.origin}/login`,
      });
      if (err) throw err;
      setSent(true);
    } catch (err: any) {
      setError(err?.message || "Could not send reset email.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF9F6] text-slate-900 flex flex-col justify-between font-sans selection:bg-amber-400">
      {/* Top Header */}
      <header className="px-6 py-4 flex items-center justify-between max-w-6xl mx-auto w-full">
        <Link to="/">
          <Logo />
        </Link>
        <div className="text-xs font-semibold text-slate-600">
          Remember password?{" "}
          <Link to="/login" className="text-amber-600 font-bold hover:underline ml-1">
            Sign In
          </Link>
        </div>
      </header>

      {/* Reset Password Card */}
      <main className="flex-1 flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-white border border-slate-200/80 rounded-3xl p-8 shadow-xl space-y-6">
          <div className="text-center space-y-1">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Reset <span className="text-amber-500">Password</span>
            </h1>
            <p className="text-xs text-slate-500">
              Enter your registered email and we'll send a password recovery link
            </p>
          </div>

          {sent ? (
            <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-2xl text-center space-y-2">
              <p className="text-xs font-bold text-emerald-800">Password Reset Link Sent!</p>
              <p className="text-[11px] text-emerald-600">
                Check your inbox for <span className="font-bold">{email}</span> to reset your password.
              </p>
              <Link
                to="/login"
                className="mt-3 inline-flex items-center gap-1 text-xs font-bold text-amber-600 hover:underline"
              >
                <ArrowLeft size={14} /> Back to Sign In
              </Link>
            </div>
          ) : (
            <form onSubmit={submit} className="space-y-4">
              <div className="space-y-1">
                <label className="text-[11px] font-bold text-slate-700 block">Email Address</label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="Enter your registered email"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>
              </div>

              {error && <div className="text-xs text-rose-600 font-medium">{error}</div>}

              <button
                type="submit"
                disabled={busy}
                className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-sm tracking-wide flex items-center justify-center gap-2"
              >
                {busy ? "Sending Link..." : "Send Reset Link"}
              </button>

              <div className="text-center pt-2">
                <Link to="/login" className="text-xs font-bold text-slate-600 hover:text-amber-600 flex items-center justify-center gap-1">
                  <ArrowLeft size={14} /> Back to Sign In
                </Link>
              </div>
            </form>
          )}
        </div>
      </main>

      {/* Trust Footer */}
      <footer className="py-6 border-t border-slate-200 bg-white">
        <div className="max-w-4xl mx-auto px-4 grid grid-cols-3 gap-4 text-center text-xs text-slate-600">
          <div className="flex items-center justify-center gap-2">
            <ShieldCheck className="w-4 h-4 text-amber-500" />
            <span><strong>Verified Trucks</strong> (100% Verified)</span>
          </div>
          <div className="flex items-center justify-center gap-2">
            <Tag className="w-4 h-4 text-amber-500" />
            <span><strong>Best Prices</strong> (Save More)</span>
          </div>
          <div className="flex items-center justify-center gap-2">
            <Headset className="w-4 h-4 text-amber-500" />
            <span><strong>24/7 Support</strong> (We're here for you)</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
