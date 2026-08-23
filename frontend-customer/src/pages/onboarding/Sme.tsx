import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { api } from "../../lib/api";
import { useAuth } from "../../hooks/useAuth";
import Logo from "../../components/Logo";
import {
  Building2,
  User,
  Phone,
  FileCheck2,
  MapPin,
  ShieldCheck,
  CheckCircle2,
  Sparkles,
  ArrowRight
} from "lucide-react";

export default function CustomerOnboarding() {
  const { profile, refreshProfile } = useAuth();
  const navigate = useNavigate();

  const [form, setForm] = useState({
    company_name: profile?.company_name || "",
    business_type: "Manufacturer",
    gstin: "07AAAAA0000A1Z5",
    full_name: profile?.full_name || "Ritik Chaurasia",
    phone: profile?.phone || "+91 98765 43210",
    city: "Delhi NCR",
  });

  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError("");

    try {
      await api.patch("/auth/profile", {
        company_name: form.company_name,
        full_name: form.full_name || profile?.full_name,
        phone: form.phone || profile?.phone,
        onboarding_complete: true,
      });
      await refreshProfile();
      navigate("/dashboard");
    } catch {
      // Local/demo fallback
      navigate("/dashboard");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF9F6] text-slate-900 font-sans selection:bg-amber-400 flex flex-col justify-between">
      {/* Header */}
      <header className="bg-white border-b border-slate-200/80 sticky top-0 z-20">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link to="/">
            <Logo />
          </Link>
          <div className="flex items-center gap-2 text-xs font-bold text-slate-500">
            <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
            <span>Customer Account Setup</span>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex items-center justify-center p-4 py-10">
        <div className="w-full max-w-xl bg-white border border-slate-200/80 rounded-3xl p-8 shadow-xl space-y-6">
          {/* Step Badge */}
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div className="space-y-1">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-100/80 text-amber-900 text-[10px] font-black tracking-wider uppercase border border-amber-300">
                <Sparkles size={12} className="text-amber-600" />
                Step 1 of 1 • Business Profile
              </span>
              <h1 className="text-2xl font-black tracking-tight text-slate-900">
                Complete Your <span className="text-amber-500">Business Details</span>
              </h1>
              <p className="text-xs text-slate-500">Set up your profile to start booking verified trucks with instant invoicing.</p>
            </div>
          </div>

          <form onSubmit={submit} className="space-y-4">
            {/* Business Name */}
            <div className="space-y-1.5">
              <label className="text-xs font-black text-slate-800 flex items-center gap-1.5">
                <Building2 size={15} className="text-amber-500" />
                Business / Company Name *
              </label>
              <input
                type="text"
                required
                value={form.company_name}
                onChange={(e) => setForm({ ...form, company_name: e.target.value })}
                placeholder="e.g. Chaurasia Enterprises Pvt Ltd"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-bold text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:bg-white transition"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {/* Business Type */}
              <div className="space-y-1.5">
                <label className="text-xs font-black text-slate-800 block">Business Category</label>
                <select
                  value={form.business_type}
                  onChange={(e) => setForm({ ...form, business_type: e.target.value })}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:bg-white transition"
                >
                  <option>Manufacturer</option>
                  <option>Wholesaler / Distributor</option>
                  <option>Trader / Retailer</option>
                  <option>Agri &amp; Produce Trader</option>
                  <option>E-commerce / D2C Brand</option>
                  <option>Individual Shipper</option>
                </select>
              </div>

              {/* GSTIN Number */}
              <div className="space-y-1.5">
                <label className="text-xs font-black text-slate-800 flex items-center gap-1.5">
                  <FileCheck2 size={15} className="text-amber-500" />
                  GSTIN (Optional for GST input)
                </label>
                <input
                  type="text"
                  value={form.gstin}
                  onChange={(e) => setForm({ ...form, gstin: e.target.value.toUpperCase() })}
                  placeholder="07AAAAA0000A1Z5"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-mono font-bold text-slate-900 uppercase placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:bg-white transition"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {/* Contact Person */}
              <div className="space-y-1.5">
                <label className="text-xs font-black text-slate-800 flex items-center gap-1.5">
                  <User size={15} className="text-amber-500" />
                  Contact Person *
                </label>
                <input
                  type="text"
                  required
                  value={form.full_name}
                  onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                  placeholder="Full Name"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-bold text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:bg-white transition"
                />
              </div>

              {/* Phone */}
              <div className="space-y-1.5">
                <label className="text-xs font-black text-slate-800 flex items-center gap-1.5">
                  <Phone size={15} className="text-amber-500" />
                  Mobile Number *
                </label>
                <input
                  type="tel"
                  required
                  value={form.phone}
                  onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  placeholder="+91 98765 43210"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-bold text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:bg-white transition"
                />
              </div>
            </div>

            {/* Operating City / Hub */}
            <div className="space-y-1.5">
              <label className="text-xs font-black text-slate-800 flex items-center gap-1.5">
                <MapPin size={15} className="text-amber-500" />
                Primary Operating City / Hub
              </label>
              <input
                type="text"
                value={form.city}
                onChange={(e) => setForm({ ...form, city: e.target.value })}
                placeholder="e.g. Delhi NCR, Mumbai, Ahmedabad"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-bold text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:bg-white transition"
              />
            </div>

            {error && <div className="text-xs text-rose-600 font-bold bg-rose-50 p-2.5 rounded-xl border border-rose-200">{error}</div>}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={busy}
              className="w-full bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black py-3.5 rounded-2xl shadow-md hover:shadow-lg transition text-sm tracking-wide flex items-center justify-center gap-2 cursor-pointer mt-2"
            >
              <span>{busy ? "Saving Profile..." : "Save and Continue to Dashboard"}</span>
              <ArrowRight size={18} />
            </button>
          </form>

          {/* Value props footer */}
          <div className="pt-2 border-t border-slate-100 grid grid-cols-3 gap-2 text-center">
            <div className="flex items-center justify-center gap-1 text-[10px] font-bold text-slate-600">
              <ShieldCheck size={13} className="text-emerald-500" />
              <span>Verified Fleets</span>
            </div>
            <div className="flex items-center justify-center gap-1 text-[10px] font-bold text-slate-600">
              <CheckCircle2 size={13} className="text-amber-500" />
              <span>Instant Invoicing</span>
            </div>
            <div className="flex items-center justify-center gap-1 text-[10px] font-bold text-slate-600">
              <CheckCircle2 size={13} className="text-blue-500" />
              <span>Live GPS Updates</span>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="py-4 border-t border-slate-200/80 bg-white text-center text-xs text-slate-500">
        © {new Date().getFullYear()} REDO Transport &amp; Logistics. Safe &amp; Reliable Freight.
      </footer>
    </div>
  );
}
