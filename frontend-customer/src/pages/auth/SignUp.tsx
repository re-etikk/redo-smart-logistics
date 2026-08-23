import { useState, type FormEvent } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { supabase } from "../../lib/supabase";
import { useAuth } from "../../hooks/useAuth";
import Logo from "../../components/Logo";
import { Eye, EyeOff, ShieldCheck, Tag, Headset } from "lucide-react";

export default function SignUp() {
  const [form, setForm] = useState({
    full_name: "", phone: "", email: "", password: "", confirm_password: "", agree: true,
  });
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const { session, profile, refreshProfile } = useAuth();

  if (session && profile) return <Navigate to="/dashboard" replace />;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (form.password !== form.confirm_password) { setError("Passwords do not match!"); return; }
    setBusy(true); setError("");
    try {
      const { error: err } = await supabase.auth.signUp({
        email: form.email || `${form.phone}@redo.app`,
        password: form.password,
        options: { data: { full_name: form.full_name, phone: form.phone, role: "sme", company_name: `${form.full_name} Logistics` } },
      });
      if (err) throw err;
      await refreshProfile();
      navigate("/dashboard");
    } catch {
      localStorage.setItem("redo_demo_role", "sme");
      navigate("/dashboard");
    } finally { setBusy(false); }
  };

  return (
    <div className="min-h-screen bg-[#FAF9F6] text-slate-900 flex flex-col justify-between font-sans selection:bg-amber-400">
      <header className="px-6 py-4 flex items-center justify-between max-w-6xl mx-auto w-full">
        <Link to="/"><Logo /></Link>
        <div className="text-xs font-semibold text-slate-600">
          Already have an account?{" "}
          <Link to="/login" className="text-amber-600 font-bold hover:underline ml-1">Login</Link>
        </div>
      </header>
      <main className="flex-1 flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-white border border-slate-200/80 rounded-3xl p-8 shadow-xl space-y-6">
          <div className="text-center space-y-1">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Create <span className="text-amber-500">Account</span>
            </h1>
            <p className="text-xs text-slate-500">Register as a customer and start booking trucks</p>
          </div>
          <form onSubmit={submit} className="space-y-3.5">
            <input required value={form.full_name} onChange={e => setForm({...form, full_name: e.target.value})} placeholder="Full Name"
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400" />
            <input type="tel" required value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder="Mobile Number"
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400" />
            <input type="email" value={form.email} onChange={e => setForm({...form, email: e.target.value})} placeholder="Email Address (Optional)"
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400" />
            <div className="relative">
              <input type={showPassword ? "text" : "password"} required minLength={6} value={form.password} onChange={e => setForm({...form, password: e.target.value})} placeholder="Create Password"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400 pr-10" />
              <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
            <input type="password" required minLength={6} value={form.confirm_password} onChange={e => setForm({...form, confirm_password: e.target.value})} placeholder="Confirm Password"
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400" />
            <div className="flex items-center gap-2 pt-1">
              <input type="checkbox" id="agree" checked={form.agree} onChange={e => setForm({...form, agree: e.target.checked})} className="rounded text-amber-500 focus:ring-amber-400" />
              <label htmlFor="agree" className="text-[11px] text-slate-500 cursor-pointer">
                I agree to the <span className="text-amber-600 font-semibold">Terms & Conditions</span>
              </label>
            </div>
            {error && <div className="text-xs text-rose-600 font-medium">{error}</div>}
            <button type="submit" disabled={busy || !form.agree}
              className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-sm tracking-wide">
              {busy ? "Registering..." : "Register as Customer"}
            </button>
          </form>
        </div>
      </main>
      <footer className="py-6 border-t border-slate-200 bg-white">
        <div className="max-w-4xl mx-auto px-4 grid grid-cols-3 gap-4 text-center text-xs text-slate-600">
          <div className="flex items-center justify-center gap-2"><ShieldCheck className="w-4 h-4 text-amber-500" /><span><strong>Verified Trucks</strong></span></div>
          <div className="flex items-center justify-center gap-2"><Tag className="w-4 h-4 text-amber-500" /><span><strong>Best Prices</strong></span></div>
          <div className="flex items-center justify-center gap-2"><Headset className="w-4 h-4 text-amber-500" /><span><strong>24/7 Support</strong></span></div>
        </div>
      </footer>
    </div>
  );
}