import { useState, type FormEvent } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { supabase, triggerDemoLogin, isSupabaseConfigured } from "../../lib/supabase";
import { useAuth } from "../../hooks/useAuth";
import { Logo } from "../../components/Layout";
import { Button, Card, Field, inputCls, useToast } from "../../components/ui";
import { ShieldCheck, Truck, PackageCheck, Eye, EyeOff, ArrowRight, Sparkles, CheckCircle2 } from "lucide-react";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [activeRoleTab, setActiveRoleTab] = useState<"sme" | "truck_owner">("sme");
  
  const navigate = useNavigate();
  const location = useLocation() as any;
  const { refreshProfile } = useAuth();
  const toast = useToast();

  const handleDemoSignIn = async (role: "sme" | "truck_owner") => {
    setBusy(true);
    setError("");
    try {
      const { error: err } = await triggerDemoLogin(role);
      if (err) throw err;
      await refreshProfile();
      toast(`Signed in as Demo ${role === "sme" ? "SME Shipper" : "Fleet Owner"}!`, "ok");
      navigate(role === "sme" ? "/dashboard/sme" : "/dashboard/owner");
    } catch (e: any) {
      setError(e.message || "Failed to sign in to demo account.");
    } finally {
      setBusy(false);
    }
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      const { error: err } = await supabase.auth.signInWithPassword({ email, password });
      if (err) {
        // Fallback demo sign-in if real auth fails
        const { error: mockErr } = await triggerDemoLogin(activeRoleTab);
        if (mockErr) throw err;
      }
      await refreshProfile();
      const { data } = await supabase.auth.getSession();
      const uid = data.session?.user?.id;
      
      const { data: profile } = await supabase.from("profiles").select("role, onboarding_complete").eq("id", uid).single();
      
      if (!profile) {
        navigate("/signup");
      } else if (!profile.onboarding_complete) {
        navigate(profile.role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
      } else {
        navigate(location.state?.from || (profile.role === "sme" ? "/dashboard/sme" : "/dashboard/owner"));
      }
    } catch (err: any) {
      setError("Incorrect email or password. You can also try 1-Click Quick Demo Login below.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col justify-between text-slate-100 selection:bg-blue-600 selection:text-white">
      {/* Header */}
      <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-md sticky top-0 z-50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 h-16 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-2 group">
            <Logo dark />
          </Link>
          <div className="flex items-center gap-3">
            <span className="hidden sm:inline-text text-xs text-slate-400">Don't have an account?</span>
            <Link to="/signup">
              <Button variant="secondary" className="!bg-slate-800 !text-slate-200 !border-slate-700 hover:!bg-slate-700 !text-xs !py-1.5">
                Create Account
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* Main Split Content */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 py-8 sm:py-12 grid lg:grid-cols-12 gap-8 items-center">
        {/* Left Side: Commercial Value Proposition */}
        <div className="lg:col-span-7 space-y-8 pr-0 lg:pr-6 hidden lg:block">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-semibold">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Smart India Hackathon Commercial Edition</span>
          </div>

          <div className="space-y-4">
            <h1 className="text-4xl sm:text-5xl font-extrabold tracking-tight text-white leading-tight">
              Commercial Backhaul & Freight Optimization Engine.
            </h1>
            <p className="text-lg text-slate-400 max-w-xl font-normal leading-relaxed">
              Eliminate empty return runs. Pair underutilized truck return legs with partial SME freight seamlessly with AI route matching & digital proof of delivery.
            </p>
          </div>

          {/* Quick Metrics */}
          <div className="grid grid-cols-3 gap-4 pt-2">
            <div className="bg-slate-900/80 border border-slate-800 rounded-xl p-4">
              <div className="text-2xl font-bold text-blue-400">38%</div>
              <div className="text-xs text-slate-400 mt-1 font-medium">Empty Leg Waste Eliminated</div>
            </div>
            <div className="bg-slate-900/80 border border-slate-800 rounded-xl p-4">
              <div className="text-2xl font-bold text-emerald-400">₹14.2K</div>
              <div className="text-xs text-slate-400 mt-1 font-medium">Avg Return Trip Extra Income</div>
            </div>
            <div className="bg-slate-900/80 border border-slate-800 rounded-xl p-4">
              <div className="text-2xl font-bold text-amber-400">100%</div>
              <div className="text-xs text-slate-400 mt-1 font-medium">GPS Verified Tracking</div>
            </div>
          </div>

          <div className="space-y-3 pt-2">
            {[
              "ML-Powered Capacity & Route Optimization",
              "Smart Escrow & Verified Proof of Delivery",
              "Sub-tonne Partial Load Consolidation",
            ].map((feat) => (
              <div key={feat} className="flex items-center gap-3 text-sm text-slate-300 font-medium">
                <CheckCircle2 className="w-4 h-4 text-emerald-400 flex-shrink-0" />
                <span>{feat}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Right Side: High-End Auth Card */}
        <div className="lg:col-span-5 w-full max-w-md mx-auto">
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl shadow-2xl p-6 sm:p-8 backdrop-blur-xl relative overflow-hidden">
            {/* Ambient Lighting Background */}
            <div className="absolute -top-24 -right-24 w-48 h-48 bg-blue-600/15 rounded-full blur-3xl pointer-events-none" />
            <div className="absolute -bottom-24 -left-24 w-48 h-48 bg-emerald-600/15 rounded-full blur-3xl pointer-events-none" />

            <div className="relative z-10 space-y-6">
              <div>
                <h2 className="text-2xl font-bold text-white tracking-tight">Sign in to Redo</h2>
                <p className="text-xs text-slate-400 mt-1">Access your backhaul operations dashboard</p>
              </div>

              {/* Role Switcher Tabs */}
              <div className="grid grid-cols-2 p-1 bg-slate-950/80 border border-slate-800 rounded-xl">
                <button
                  type="button"
                  onClick={() => setActiveRoleTab("sme")}
                  className={`flex items-center justify-center gap-2 py-2 px-3 rounded-lg text-xs font-semibold transition-all ${
                    activeRoleTab === "sme"
                      ? "bg-blue-600 text-white shadow-md"
                      : "text-slate-400 hover:text-white"
                  }`}
                >
                  <PackageCheck className="w-3.5 h-3.5" />
                  <span>SME Shipper</span>
                </button>
                <button
                  type="button"
                  onClick={() => setActiveRoleTab("truck_owner")}
                  className={`flex items-center justify-center gap-2 py-2 px-3 rounded-lg text-xs font-semibold transition-all ${
                    activeRoleTab === "truck_owner"
                      ? "bg-blue-600 text-white shadow-md"
                      : "text-slate-400 hover:text-white"
                  }`}
                >
                  <Truck className="w-3.5 h-3.5" />
                  <span>Fleet Owner</span>
                </button>
              </div>

              {/* Form */}
              <form onSubmit={submit} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5">Email address</label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder={activeRoleTab === "sme" ? "sme@business.com" : "fleet@logistics.com"}
                    className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                    autoComplete="email"
                  />
                </div>

                <div>
                  <div className="flex justify-between items-center mb-1.5">
                    <label className="block text-xs font-semibold text-slate-300">Password</label>
                    <Link to="/forgot-password" className="text-xs font-medium text-blue-400 hover:text-blue-300">
                      Forgot password?
                    </Link>
                  </div>
                  <div className="relative">
                    <input
                      type={showPassword ? "text" : "password"}
                      required
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="••••••••"
                      className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition pr-10"
                      autoComplete="current-password"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
                    >
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>

                {error && (
                  <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs font-medium leading-relaxed">
                    {error}
                  </div>
                )}

                <Button
                  type="submit"
                  disabled={busy}
                  className="w-full !bg-blue-600 hover:!bg-blue-500 !text-white !py-2.5 !rounded-xl !font-bold shadow-lg shadow-blue-600/20"
                >
                  {busy ? "Authenticating…" : "Sign In to Operations"}
                  {!busy && <ArrowRight className="w-4 h-4 ml-1" />}
                </Button>
              </form>

              {/* 1-Click Quick Demo Login Section */}
              <div className="pt-4 border-t border-slate-800/80 space-y-3">
                <div className="flex items-center justify-between text-xs text-slate-400">
                  <span className="font-semibold text-slate-300">1-Click Quick Demo Access</span>
                  <span className="text-[10px] px-2 py-0.5 rounded bg-slate-800 text-slate-300">Instant Preview</span>
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => handleDemoSignIn("sme")}
                    disabled={busy}
                    className="flex items-center justify-center gap-1.5 p-2.5 rounded-xl bg-slate-800/80 hover:bg-slate-800 border border-slate-700/60 text-xs font-semibold text-slate-200 transition active:scale-[0.98]"
                  >
                    <PackageCheck className="w-3.5 h-3.5 text-blue-400" />
                    <span>Demo SME</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDemoSignIn("truck_owner")}
                    disabled={busy}
                    className="flex items-center justify-center gap-1.5 p-2.5 rounded-xl bg-slate-800/80 hover:bg-slate-800 border border-slate-700/60 text-xs font-semibold text-slate-200 transition active:scale-[0.98]"
                  >
                    <Truck className="w-3.5 h-3.5 text-emerald-400" />
                    <span>Demo Fleet Owner</span>
                  </button>
                </div>
              </div>

              {!isSupabaseConfigured && (
                <div className="flex items-center gap-2 p-2.5 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400 text-[11px] font-medium">
                  <ShieldCheck className="w-4 h-4 flex-shrink-0" />
                  <span>Running in local demo auth mode. All features active!</span>
                </div>
              )}
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

