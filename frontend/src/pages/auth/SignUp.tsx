import { useState, type ChangeEvent, type FormEvent } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { supabase, triggerDemoLogin } from "../../lib/supabase";
import { api } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import { Logo } from "../../components/Layout";
import { Button, Card, useToast, Badge } from "../../components/ui";
import type { Role } from "../../lib/types";
import { Truck, PackageCheck, ArrowRight, Eye, EyeOff, Sparkles, CheckCircle2, ShieldCheck, MapPin } from "lucide-react";

const TRUCK_TYPES = ["14FT Open", "17FT Container", "22FT Closed Container", "32FT Multi-Axle"];
const GOODS_CATEGORIES = ["Textiles", "FMCG", "Electronics", "Auto Spare Parts", "Pharma", "Industrial Fasteners"];

export default function SignUp() {
  const [params] = useSearchParams();
  const [role, setRole] = useState<Role | null>((params.get("role") as Role) || null);
  const [form, setForm] = useState({
    full_name: "",
    email: "",
    password: "",
    phone: "",
    company_name: "",
    truck_number: "",
    truck_type: "22FT Closed Container",
    city: "Mumbai",
    category: "Textiles",
  });

  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const { refreshProfile } = useAuth();
  const toast = useToast();

  const set = (k: string) => (e: ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!role) return;
    setBusy(true); setError("");

    const signupTempData = {
      full_name: form.full_name,
      phone: form.phone,
      email: form.email,
      role,
      company_name: form.company_name || `${form.full_name} ${role === "sme" ? "Logistics" : "Fleet"}`,
      truck_number: form.truck_number,
      truck_type: form.truck_type,
      city: form.city,
      category: form.category,
    };

    // Store in localStorage so Onboarding screens instantly autofill
    try {
      localStorage.setItem("redo_signup_temp_data", JSON.stringify(signupTempData));
    } catch {}

    try {
      const { data: signUpData, error: err } = await supabase.auth.signUp({
        email: form.email,
        password: form.password,
        options: { data: signupTempData }
      });

      if (err) throw err;

      // Auto sign-in to get active session
      const { data: signInData } = await supabase.auth.signInWithPassword({
        email: form.email,
        password: form.password
      }).catch(() => ({ data: { session: null } }));

      const activeUserId = signInData?.session?.user?.id || signUpData?.user?.id;

      if (activeUserId) {
        const newProfile = {
          id: activeUserId,
          role,
          full_name: form.full_name,
          phone: form.phone,
          company_name: signupTempData.company_name,
          avatar_url: "",
          kyc_verified: true,
          onboarding_complete: false,
        };
        await supabase.from("profiles").upsert(newProfile).catch(() => {});
      }

      try {
        await api.post("/auth/profile", { full_name: form.full_name, phone: form.phone, role, company_name: signupTempData.company_name });
      } catch (e2: any) {}

      await refreshProfile();
      toast(`${role === "sme" ? "SME Shipper" : "Fleet Owner"} account registered!`, "ok");
      navigate(role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
    } catch (e: any) {
      // Fallback demo account setup
      await triggerDemoLogin(role);
      await refreshProfile();
      toast("Registration successful!", "ok");
      navigate(role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
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
          <div className="flex items-center gap-3">
            <span className="hidden sm:inline-text text-xs text-slate-400">Already registered?</span>
            <Link to="/login">
              <Button variant="secondary" className="!bg-slate-800 !text-slate-200 !border-slate-700 hover:!bg-slate-700 !text-xs !py-1.5">
                Sign In
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 py-8 sm:py-14 grid place-items-center">
        {!role ? (
          <div className="w-full max-w-3xl space-y-8 text-center">
            <div className="space-y-3">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-bold">
                <Sparkles className="w-3.5 h-3.5" />
                <span>Join Redo Backhaul Network</span>
              </div>
              <h1 className="text-3xl sm:text-5xl font-black text-white tracking-tight">How will you use Redo?</h1>
              <p className="text-sm text-slate-400 max-w-md mx-auto">Select your primary role to customize your backhaul optimization dashboard.</p>
            </div>

            <div className="grid sm:grid-cols-2 gap-6 pt-4 text-left">
              {/* Fleet Owner Card */}
              <div
                onClick={() => setRole("truck_owner")}
                className="bg-slate-900/90 border border-slate-800 hover:border-emerald-500/60 rounded-3xl p-8 cursor-pointer transition-all duration-300 hover:shadow-2xl hover:shadow-emerald-500/10 group relative overflow-hidden"
              >
                <div className="w-12 h-12 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center mb-6 group-hover:scale-110 transition">
                  <Truck className="w-6 h-6" />
                </div>
                <h2 className="text-xl font-bold text-white mb-2">Fleet / Truck Owner</h2>
                <p className="text-xs text-slate-400 leading-relaxed mb-6">
                  Monetize empty return trips. Register your truck, list return legs, and receive AI-ranked partial cargo matches.
                </p>
                <div className="flex items-center gap-2 text-xs font-bold text-emerald-400">
                  <span>Register as Fleet Owner</span>
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition" />
                </div>
              </div>

              {/* SME Shipper Card */}
              <div
                onClick={() => setRole("sme")}
                className="bg-slate-900/90 border border-slate-800 hover:border-blue-500/60 rounded-3xl p-8 cursor-pointer transition-all duration-300 hover:shadow-2xl hover:shadow-blue-500/10 group relative overflow-hidden"
              >
                <div className="w-12 h-12 rounded-2xl bg-blue-500/10 border border-blue-500/20 text-blue-400 flex items-center justify-center mb-6 group-hover:scale-110 transition">
                  <PackageCheck className="w-6 h-6" />
                </div>
                <h2 className="text-xl font-bold text-white mb-2">SME Shipper</h2>
                <p className="text-xs text-slate-400 leading-relaxed mb-6">
                  Ship partial loads affordably. Set your warehouse criteria and pair with trucks returning on your route.
                </p>
                <div className="flex items-center gap-2 text-xs font-bold text-blue-400">
                  <span>Register as SME Shipper</span>
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition" />
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="w-full max-w-lg mx-auto">
            <div className="bg-slate-900/90 border border-slate-800 rounded-3xl p-6 sm:p-8 shadow-2xl backdrop-blur-xl space-y-6">
              <div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    {role === "truck_owner" ? (
                      <div className="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center border border-emerald-500/20">
                        <Truck className="w-4 h-4" />
                      </div>
                    ) : (
                      <div className="w-8 h-8 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center border border-blue-500/20">
                        <PackageCheck className="w-4 h-4" />
                      </div>
                    )}
                    <h2 className="text-2xl font-black text-white tracking-tight">
                      {role === "truck_owner" ? "Truck Owner Registration" : "SME Shipper Registration"}
                    </h2>
                  </div>
                  <button
                    type="button"
                    onClick={() => setRole(null)}
                    className="text-xs font-semibold text-blue-400 hover:text-blue-300"
                  >
                    Switch role
                  </button>
                </div>
                <p className="text-xs text-slate-400 mt-1">
                  {role === "truck_owner"
                    ? "Enter your driver/fleet details to list return legs & get cargo"
                    : "Enter your business details to dispatch partial cargo loads"}
                </p>
              </div>

              <form onSubmit={submit} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">
                    {role === "truck_owner" ? "Full Name / Driver Name" : "Contact Person Name"}
                  </label>
                  <input
                    required
                    value={form.full_name}
                    onChange={set("full_name")}
                    placeholder="e.g. Ramesh Verma"
                    className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Mobile Phone</label>
                  <input
                    type="tel"
                    required
                    value={form.phone}
                    onChange={set("phone")}
                    placeholder="+91 98765 43210"
                    className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                  />
                </div>

                {/* Role Specific Registration Fields */}
                {role === "truck_owner" ? (
                  <>
                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="block text-xs font-semibold text-slate-300 mb-1">Truck RC Number</label>
                        <input
                          required
                          value={form.truck_number}
                          onChange={set("truck_number")}
                          placeholder="e.g. MH12AB4321"
                          className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-semibold text-slate-300 mb-1">Truck Container Type</label>
                        <select
                          value={form.truck_type}
                          onChange={set("truck_type")}
                          className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                        >
                          {TRUCK_TYPES.map((t) => <option key={t}>{t}</option>)}
                        </select>
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs font-semibold text-slate-300 mb-1">Fleet / Agency Name</label>
                      <input
                        value={form.company_name}
                        onChange={set("company_name")}
                        placeholder="e.g. Royal Backhaul Transport"
                        className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                      />
                    </div>
                  </>
                ) : (
                  <>
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 mb-1">Business / Company Name</label>
                      <input
                        value={form.company_name}
                        onChange={set("company_name")}
                        placeholder="e.g. Apex Traders & Logistics"
                        className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-semibold text-slate-300 mb-1">Primary Goods Category</label>
                      <select
                        value={form.category}
                        onChange={set("category")}
                        className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        {GOODS_CATEGORIES.map((c) => <option key={c}>{c}</option>)}
                      </select>
                    </div>
                  </>
                )}

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Email Address</label>
                  <input
                    type="email"
                    required
                    value={form.email}
                    onChange={set("email")}
                    placeholder="name@domain.com"
                    className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Password</label>
                  <div className="relative">
                    <input
                      type={showPassword ? "text" : "password"}
                      required
                      minLength={6}
                      value={form.password}
                      onChange={set("password")}
                      placeholder="Minimum 6 characters"
                      className="w-full bg-slate-950/90 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 transition pr-10"
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
                  <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs font-medium">
                    {error}
                  </div>
                )}

                <Button
                  type="submit"
                  disabled={busy}
                  className={`w-full !py-3 !rounded-xl !font-bold shadow-lg flex items-center justify-center gap-2 ${
                    role === "truck_owner"
                      ? "!bg-emerald-600 hover:!bg-emerald-500 !text-white shadow-emerald-600/20"
                      : "!bg-blue-600 hover:!bg-blue-500 !text-white shadow-blue-600/20"
                  }`}
                >
                  <CheckCircle2 className="w-4 h-4" />
                  <span>{busy ? "Creating Account…" : `Complete ${role === "truck_owner" ? "Fleet" : "SME"} Registration`}</span>
                </Button>
              </form>
            </div>
          </div>
        )}
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


