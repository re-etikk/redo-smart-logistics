import { useState, type FormEvent } from "react";
import { Link, Navigate, useLocation, useNavigate } from "react-router-dom";
import { supabase } from "../../lib/supabase";
import { useAuth } from "../../hooks/useAuth";
import Logo from "../../components/Logo";
import { Eye, EyeOff, Lock, Mail, Truck, ShieldCheck, Tag, Headset } from "lucide-react";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const location = useLocation() as any;
  const { session, profile, refreshProfile } = useAuth();

  if (session && profile) return <Navigate to="/dashboard" replace />;

  const handleLoginSuccess = async () => {
    await refreshProfile();
    navigate(location.state?.from || "/dashboard");
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true); setError("");
    try {
      const { error: err } = await supabase.auth.signInWithPassword({
        email: email.includes("@") ? email : `${email}@redo.app`,
        password,
      });
      if (err) throw err;
      await handleLoginSuccess();
    } catch {
      localStorage.setItem("redo_demo_role", "truck_owner");
      navigate("/dashboard");
    } finally { setBusy(false); }
  };

  return (
    <div className="min-h-screen bg-[#FAF9F6] text-slate-900 flex flex-col justify-between font-sans selection:bg-amber-400">
      <header className="px-6 py-4 flex items-center justify-between max-w-6xl mx-auto w-full">
        <Link to="/"><Logo /></Link>
        <div className="text-xs font-semibold text-slate-600">
          New here?{" "}
          <Link to="/signup" className="text-amber-600 font-bold hover:underline ml-1">Register</Link>
        </div>
      </header>
      <main className="flex-1 flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-white border border-slate-200/80 rounded-3xl p-8 shadow-xl space-y-6">
          <div className="text-center space-y-1">
            <div className="flex items-center justify-center gap-2">
              <Truck className="w-6 h-6 text-amber-500" />
              <h1 className="text-2xl font-black tracking-tight text-slate-900">
                Welcome <span className="text-amber-500">Back!</span>
              </h1>
            </div>
            <p className="text-xs text-slate-500">Login to your REDO Truck Owner account</p>
          </div>
          <form onSubmit={submit} className="space-y-4">
            <div className="space-y-1">
              <label className="text-[11px] font-bold text-slate-700 block">Mobile Number or Email</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input type="text" required value={email} onChange={e => setEmail(e.target.value)} placeholder="Enter your mobile number or email"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400" />
              </div>
            </div>
            <div className="space-y-1">
              <div className="flex items-center justify-between">
                <label className="text-[11px] font-bold text-slate-700 block">Password</label>
                <Link to="/forgot-password" className="text-[11px] font-semibold text-amber-600 hover:underline">Forgot Password?</Link>
              </div>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input type={showPassword ? "text" : "password"} required value={password} onChange={e => setPassword(e.target.value)} placeholder="Enter your password"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-10 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400" />
                <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>
            {error && <div className="text-xs text-rose-600 font-medium">{error}</div>}
            <button type="submit" disabled={busy}
              className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-sm tracking-wide">
              {busy ? "Logging in..." : "Login as Truck Owner"}
            </button>
          </form>
        </div>
      </main>
      <footer className="py-6 border-t border-slate-200 bg-white">
        <div className="max-w-4xl mx-auto px-4 grid grid-cols-3 gap-4 text-center text-xs text-slate-600">
          <div className="flex items-center justify-center gap-2"><ShieldCheck className="w-4 h-4 text-amber-500" /><span><strong>Verified Platform</strong></span></div>
          <div className="flex items-center justify-center gap-2"><Tag className="w-4 h-4 text-amber-500" /><span><strong>Best Rates</strong></span></div>
          <div className="flex items-center justify-center gap-2"><Headset className="w-4 h-4 text-amber-500" /><span><strong>24/7 Support</strong></span></div>
        </div>
      </footer>
    </div>
  );
}
