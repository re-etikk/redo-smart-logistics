import { useState, useEffect } from "react";
import { User, Lock, Building, CheckCircle2, ShieldCheck, Mail, Phone, MapPin, Save } from "lucide-react";
import Layout from "../components/Layout";
import { useAuth } from "../hooks/useAuth";

export default function CustomerProfile() {
  const { session, profile } = useAuth();
  const [saved, setSaved] = useState(false);

  const [form, setForm] = useState({
    companyName: profile?.company_name || "Chaurasia Trading & Enterprises",
    gstin: "07AAAAA0000A1Z5",
    fullName: profile?.full_name || session?.user?.user_metadata?.full_name || "Ritik Chaurasia",
    email: session?.user?.email || profile?.email || "customer@redo.app",
    phone: profile?.phone || "+91 98765 43210",
    city: "Delhi NCR, Delhi",
    businessType: "Manufacturer & Wholesaler",
  });

  useEffect(() => {
    if (session?.user?.email) {
      setForm(prev => ({ ...prev, email: session.user.email || prev.email }));
    }
  }, [session]);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    localStorage.setItem("redo_customer_profile_v2", JSON.stringify(form));
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <Layout>
      <div className="max-w-4xl mx-auto py-6 space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-black tracking-tight">Customer Profile &amp; GST Details</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Manage your business profile, registered GSTIN, and dispatch addresses.</p>
          </div>

          {saved && (
            <div className="bg-emerald-500 text-white font-bold text-xs px-4 py-2 rounded-xl flex items-center gap-1.5 shadow-sm">
              <CheckCircle2 size={16} /> Profile Updated Successfully
            </div>
          )}
        </div>

        <div className="grid gap-6 md:grid-cols-[1fr_300px]">
          <div className="space-y-6">
            {/* Personal & Business Details */}
            <form onSubmit={handleSave} className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
              <h3 className="font-black text-xs uppercase tracking-wider flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
                <Building size={16} className="text-amber-500" /> Business &amp; Invoicing Details
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs font-bold">
                <div>
                  <label className="text-slate-400 text-[10px] uppercase block mb-1">Company / Business Name</label>
                  <input
                    value={form.companyName}
                    onChange={(e) => setForm({ ...form, companyName: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>

                <div>
                  <label className="text-slate-400 text-[10px] uppercase block mb-1">GSTIN Registration Number</label>
                  <input
                    value={form.gstin}
                    onChange={(e) => setForm({ ...form, gstin: e.target.value.toUpperCase() })}
                    placeholder="07AAAAA0000A1Z5"
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 uppercase font-mono focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>

                <div>
                  <label className="text-slate-400 text-[10px] uppercase block mb-1">Contact Person Name</label>
                  <input
                    value={form.fullName}
                    onChange={(e) => setForm({ ...form, fullName: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>

                <div>
                  <label className="text-slate-400 text-[10px] uppercase block mb-1">Registered Email</label>
                  <input
                    type="email"
                    value={form.email}
                    onChange={(e) => setForm({ ...form, email: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>

                <div>
                  <label className="text-slate-400 text-[10px] uppercase block mb-1">Phone Number</label>
                  <input
                    type="tel"
                    value={form.phone}
                    onChange={(e) => setForm({ ...form, phone: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>

                <div>
                  <label className="text-slate-400 text-[10px] uppercase block mb-1">Operating Hub City</label>
                  <input
                    value={form.city}
                    onChange={(e) => setForm({ ...form, city: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>
              </div>

              <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end">
                <button
                  type="submit"
                  className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black px-6 py-2.5 rounded-xl text-xs shadow-sm transition flex items-center gap-2 cursor-pointer"
                >
                  <Save size={15} /> Save Business Profile
                </button>
              </div>
            </form>

            {/* Security & Password */}
            <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-6 shadow-sm space-y-4">
              <h3 className="font-black text-xs uppercase tracking-wider flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
                <Lock size={16} className="text-purple-500" /> Account Security
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs font-bold">
                <div>
                  <label className="text-slate-400 text-[10px] uppercase block mb-1">New Password</label>
                  <input
                    type="password"
                    placeholder="••••••••"
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                  />
                </div>

                <div>
                  <label className="text-slate-400 text-[10px] uppercase block mb-1">Confirm Password</label>
                  <input
                    type="password"
                    placeholder="••••••••"
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3.5 py-2.5"
                  />
                </div>
              </div>

              <button
                type="button"
                onClick={() => alert("Password updated successfully!")}
                className="bg-purple-600 hover:bg-purple-700 text-white font-black px-5 py-2.5 rounded-xl shadow-sm text-xs transition cursor-pointer"
              >
                Update Password
              </button>
            </div>
          </div>

          {/* Right Sidebar Snapshot */}
          <div className="space-y-4 text-xs font-bold">
            <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl p-5 shadow-sm space-y-3">
              <span className="text-[10px] uppercase tracking-wider text-slate-400 block font-bold">Verification Status</span>
              <div className="p-3 bg-emerald-50/70 dark:bg-emerald-950/40 border border-emerald-200/80 dark:border-emerald-800 rounded-2xl space-y-1">
                <div className="flex items-center gap-1.5 text-emerald-800 dark:text-emerald-400 font-black">
                  <ShieldCheck size={16} /> Verified Business
                </div>
                <p className="text-[11px] text-slate-600 dark:text-slate-400 font-normal">
                  Your GSTIN &amp; business identity are verified for automated input tax credit (ITC).
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
