import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import { supabase, triggerDemoLogin } from "../../lib/supabase";
import { useAuth } from "../../hooks/useAuth";
import { Logo } from "../../components/Layout";
import { Eye, EyeOff, ShieldCheck, Tag, Headset } from "lucide-react";

export default function SignUp() {
  const [role, setRole] = useState<"sme" | "truck_owner">("sme");
  const [form, setForm] = useState({
    full_name: "",
    phone: "",
    email: "",
    password: "",
    confirm_password: "",
    agree: true,
  });

  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const { refreshProfile } = useAuth();

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (form.password !== form.confirm_password) {
      setError("Passwords do not match!");
      return;
    }
    setBusy(true);
    setError("");

    const signupTempData = {
      full_name: form.full_name,
      phone: form.phone,
      email: form.email,
      role,
      company_name: `${form.full_name} ${role === "sme" ? "Logistics" : "Fleet"}`,
    };

    try {
      localStorage.setItem("redo_signup_temp_data", JSON.stringify(signupTempData));
    } catch {}

    try {
      const { error: err } = await supabase.auth.signUp({
        email: form.email || `${form.phone}@redo.app`,
        password: form.password,
        options: { data: signupTempData },
      });
      if (err) throw err;

      await refreshProfile();
      navigate(role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
    } catch {
      await triggerDemoLogin(role);
      await refreshProfile();
      navigate(role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
    } finally {
      setBusy(false);
    }
  };

  const handleSocialLogin = async (provider: "google" | "facebook" | "apple") => {
    setBusy(true);
    try {
      const { error: err } = await supabase.auth.signInWithOAuth({
        provider,
        options: { redirectTo: window.location.origin },
      });
      if (err) throw err;
    } catch {
      await triggerDemoLogin(role);
      await refreshProfile();
      navigate(role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
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
          Already have an account?{" "}
          <Link to="/login" className="text-amber-600 font-bold hover:underline ml-1">
            Login
          </Link>
        </div>
      </header>

      {/* Main Register Form Card */}
      <main className="flex-1 flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-white border border-slate-200/80 rounded-3xl p-8 shadow-xl space-y-6">
          <div className="text-center space-y-1">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Create <span className="text-amber-500">Account</span>
            </h1>
            <p className="text-xs text-slate-500">Sign up and start booking or managing trucks easily</p>
          </div>

          {/* Segmented Switch Role Picker */}
          <div className="grid grid-cols-2 p-1 bg-slate-100 rounded-2xl border border-slate-200/60 gap-1 text-xs font-bold">
            <button
              type="button"
              onClick={() => setRole("sme")}
              className={`py-2.5 rounded-xl transition flex items-center justify-center gap-1.5 ${
                role === "sme"
                  ? "bg-[#FFC800] text-slate-900 shadow-sm border border-amber-400"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              <span>Shipper / Customer</span>
            </button>
            <button
              type="button"
              onClick={() => setRole("truck_owner")}
              className={`py-2.5 rounded-xl transition flex items-center justify-center gap-1.5 ${
                role === "truck_owner"
                  ? "bg-[#FFC800] text-slate-900 shadow-sm border border-amber-400"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              <span>Truck Owner</span>
            </button>
          </div>

          <form onSubmit={submit} className="space-y-3.5">
            <div>
              <input
                required
                value={form.full_name}
                onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                placeholder="Full Name"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
            </div>

            <div>
              <input
                type="tel"
                required
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                placeholder="Mobile Number"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
            </div>

            <div>
              <input
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                placeholder="Email Address (Optional)"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
            </div>

            <div className="relative">
              <input
                type={showPassword ? "text" : "password"}
                required
                minLength={6}
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                placeholder="Create Password"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400 pr-10"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>

            <div className="relative">
              <input
                type={showConfirmPassword ? "text" : "password"}
                required
                minLength={6}
                value={form.confirm_password}
                onChange={(e) => setForm({ ...form, confirm_password: e.target.value })}
                placeholder="Confirm Password"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400 pr-10"
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>

            <div className="flex items-center gap-2 pt-1">
              <input
                type="checkbox"
                id="agree"
                checked={form.agree}
                onChange={(e) => setForm({ ...form, agree: e.target.checked })}
                className="rounded text-amber-500 focus:ring-amber-400"
              />
              <label htmlFor="agree" className="text-[11px] text-slate-500 cursor-pointer">
                I agree to the <span className="text-amber-600 font-semibold">Terms & Conditions</span> and <span className="text-amber-600 font-semibold">Privacy Policy</span>
              </label>
            </div>

            {error && <div className="text-xs text-rose-600 font-medium">{error}</div>}

            <button
              type="submit"
              disabled={busy || !form.agree}
              className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-sm tracking-wide"
            >
              {busy ? "Registering..." : "Register"}
            </button>
          </form>

          {/* Social Auth */}
          <div className="space-y-3 pt-2">
            <div className="relative text-center text-[11px] text-slate-400">
              <span className="bg-white px-2 relative z-10">or continue with</span>
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-slate-200"></div>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-2">
              <button
                type="button"
                onClick={() => handleSocialLogin("google")}
                className="py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50 flex items-center justify-center gap-1.5"
              >
                Google
              </button>
              <button
                type="button"
                onClick={() => handleSocialLogin("facebook")}
                className="py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50 flex items-center justify-center gap-1.5"
              >
                Facebook
              </button>
              <button
                type="button"
                onClick={() => handleSocialLogin("apple")}
                className="py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50 flex items-center justify-center gap-1.5"
              >
                Apple
              </button>
            </div>
          </div>
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