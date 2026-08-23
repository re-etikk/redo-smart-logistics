import { useState } from "react";
import { User, Lock, Building, CheckCircle2 } from "lucide-react";
import Layout from "../components/Layout";
import { useAuth } from "../hooks/useAuth";

export default function CustomerProfile() {
  const { profile } = useAuth();
  const [saved, setSaved] = useState(false);
  const [companyName, setCompanyName] = useState(profile?.company_name || "Ritik Logistics & Trade Ltd");
  const [gstin, setGstin] = useState("07AAAAA0000A1Z5");
  const [fullName, setFullName] = useState(profile?.full_name || "Ritik Sharma");
  const [phone, setPhone] = useState(profile?.phone || "+91 98765 43210");

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <Layout>
      <div className="max-w-4xl mx-auto py-6 space-y-6">
        <div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">Customer Profile &amp; Settings</h1>
          <p className="text-xs text-slate-500 mt-0.5">Manage your business details, GSTIN registration, and account preferences.</p>
        </div>

        <div className="grid gap-6 md:grid-cols-[1fr_300px]">
          <div className="space-y-6">
            {/* Personal & Business Details */}
            <form onSubmit={handleSave} className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-4">
              <h3 className="font-black text-slate-900 text-xs flex items-center gap-2 border-b border-slate-100 pb-3">
                <Building size={16} className="text-amber-500" /> Business &amp; Profile Details
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs font-bold">
                <div>
                  <label className="text-slate-500 text-[10px] uppercase block mb-1">Company / Business Name</label>
                  <input
                    value={companyName}
                    onChange={(e) => setCompanyName(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>

                <div>
                  <label className="text-slate-500 text-[10px] uppercase block mb-1">GSTIN Registration Number</label>
                  <input
                    value={gstin}
                    onChange={(e) => setGstin(e.target.value)}
                    placeholder="e.g. 07AAAAA0000A1Z5"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400 uppercase font-mono"
                  />
                </div>

                <div>
                  <label className="text-slate-500 text-[10px] uppercase block mb-1">Contact Person Name</label>
                  <input
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>

                <div>
                  <label className="text-slate-500 text-[10px] uppercase block mb-1">Mobile Phone Number</label>
                  <input
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>
              </div>

              <div className="flex items-center gap-3 pt-2">
                <button type="submit" className="bg-[#FFC800] hover:bg-amber-400 text-slate-950 font-black text-xs px-5 py-2.5 rounded-xl shadow-sm transition">
                  Save Business Profile
                </button>
                {saved && (
                  <span className="text-xs font-bold text-emerald-600 flex items-center gap-1">
                    <CheckCircle2 size={15} /> Saved successfully!
                  </span>
                )}
              </div>
            </form>

            {/* Account Security */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-4">
              <h3 className="font-black text-slate-900 text-xs flex items-center gap-2 border-b border-slate-100 pb-3">
                <Lock size={16} className="text-purple-500" /> Security &amp; Password
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs font-bold">
                <div>
                  <label className="text-slate-500 text-[10px] uppercase block mb-1">New Password</label>
                  <input type="password" placeholder="Enter new password" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-900" />
                </div>

                <div>
                  <label className="text-slate-500 text-[10px] uppercase block mb-1">Confirm Password</label>
                  <input type="password" placeholder="Confirm new password" className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-900" />
                </div>
              </div>

              <button className="bg-purple-600 hover:bg-purple-700 text-white font-black text-xs px-5 py-2.5 rounded-xl shadow-sm transition">
                Update Password
              </button>
            </div>
          </div>

          {/* Right Sidebar Avatar & Verification Badge */}
          <div className="space-y-6">
            <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm space-y-4 text-center">
              <div className="relative mx-auto w-20 h-20 rounded-full bg-slate-900 text-white flex items-center justify-center font-black text-2xl border-2 border-amber-400 shadow-md">
                {(fullName || "C").charAt(0)}
              </div>
              <div>
                <h4 className="font-black text-slate-900 text-sm">{fullName}</h4>
                <span className="text-[10px] font-extrabold text-emerald-700 bg-emerald-100 px-2.5 py-0.5 rounded-full inline-block mt-1">
                  ✔ Verified Shipper
                </span>
              </div>
              <button className="w-full bg-slate-50 hover:bg-slate-100 text-slate-800 font-bold text-xs py-2 rounded-xl border border-slate-200">
                Change Profile Photo
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
