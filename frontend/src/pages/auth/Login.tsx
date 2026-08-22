import { useState, type FormEvent } from "react";
import { Link, Navigate, useLocation, useNavigate } from "react-router-dom";
import { supabase, triggerDemoLogin } from "../../lib/supabase";
import { useAuth } from "../../hooks/useAuth";
import { Logo } from "../../components/Layout";
import { Eye, EyeOff, Lock, Mail, ShieldCheck, Tag, Headset } from "lucide-react";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const location = useLocation() as any;
  const { session, profile, refreshProfile } = useAuth();

  if (session && profile) {
    const dest = profile.role === "truck_owner" ? "/dashboard/owner" : "/dashboard/sme";
    return <Navigate to={dest} replace />;
  }

  const handleLoginSuccess = async () => {
    try {
      await refreshProfile();
      const { data } = await supabase.auth.getSession();
      const uid = data.session?.user.id;
      if (!uid) {
        setError("Session not found. Please try logging in again.");
        return;
      }
      const { data: prof, error: profErr } = await supabase
        .from("profiles")
        .select("role, onboarding_complete")
        .eq("id", uid)
        .single();

      if (profErr || !prof) {
        navigate("/signup");
      } else if (!prof.onboarding_complete) {
        navigate(prof.role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
      } else {
        navigate(location.state?.from || (prof.role === "sme" ? "/dashboard/sme" : "/dashboard/owner"));
      }
    } catch (err: any) {
      setError(err?.message || "Something went wrong while loading your profile.");
    }
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      const { error: err } = await supabase.auth.signInWithPassword({
        email: email.includes("@") ? email : `${email}@redo.app`,
        password,
      });
      if (err) throw err;
      await handleLoginSuccess();
    } catch (err: any) {
      setError(err?.message || "Login failed. Please check your credentials.");
    } finally {
      setBusy(false);
    }
  };

  const quickDemoLogin = async (role: "sme" | "truck_owner") => {
    setBusy(true);
    setError("");
    try {
      const result = await triggerDemoLogin(role);
      if (!result.success) {
        setError(result.error || "Demo login failed. Demo account may not be seeded yet.");
        return;
      }
      await handleLoginSuccess();
    } catch (err: any) {
      setError(err?.message || "Something went wrong.");
    } finally {
      setBusy(false);
    }
  };

  const handleSocialLogin = async (provider: "google" | "facebook" | "apple") => {
    setBusy(true);
    try {
      const { error: err } = await supabase.auth.signInWithOAuth({
        provider,
        options: { redirectTo: `${window.location.origin}/dashboard/sme` },
      });
      if (err) throw err;
    } catch (err: any) {
      if (err?.message) setError(err.message);
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
          New here?{" "}
          <Link to="/signup" className="text-amber-600 font-bold hover:underline ml-1">
            Register
          </Link>
        </div>
      </header>

      {/* Main Login Card */}
      <main className="flex-1 flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-white border border-slate-200/80 rounded-3xl p-8 shadow-xl space-y-6">
          <div className="text-center space-y-1">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Welcome <span className="text-amber-500">Back!</span>
            </h1>
            <p className="text-xs text-slate-500">Login to your Redo account</p>
          </div>

          <form onSubmit={submit} className="space-y-4">
            <div className="space-y-1">
              <label className="text-[11px] font-bold text-slate-700 block">Mobile Number or Email</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Enter your mobile number or email"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400"
                />
              </div>
            </div>

            <div className="space-y-1">
              <div className="flex items-center justify-between">
                <label className="text-[11px] font-bold text-slate-700 block">Password</label>
                <Link to="/forgot-password" className="text-[11px] font-semibold text-amber-600 hover:underline">
                  Forgot Password?
                </Link>
              </div>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type={showPassword ? "text" : "password"}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-10 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {error && <div className="text-xs text-rose-600 font-medium">{error}</div>}

            <button
              type="submit"
              disabled={busy}
              className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl shadow-md transition text-sm tracking-wide"
            >
              {busy ? "Logging in..." : "Login"}
            </button>
          </form>

          {/* Quick Demo Access Buttons */}
          <div className="pt-1 border-t border-slate-100">
            <p className="text-[10px] text-slate-400 font-semibold text-center mb-2">1-Click Quick Demo Sign In:</p>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => quickDemoLogin("sme")}
                className="py-2 px-3 rounded-xl bg-blue-50 border border-blue-200 text-blue-700 text-xs font-bold hover:bg-blue-100 transition"
              >
                Shipper Demo
              </button>
              <button
                type="button"
                onClick={() => quickDemoLogin("truck_owner")}
                className="py-2 px-3 rounded-xl bg-amber-50 border border-amber-300 text-amber-900 text-xs font-bold hover:bg-amber-100 transition"
              >
                Truck Owner Demo
              </button>
            </div>
          </div>

          {/* Social Auth */}
          <div className="space-y-3 pt-1">
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
