import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import { supabase } from "../../lib/supabase";
import { Logo } from "../../components/Layout";
import { Button, Card, Field, inputCls, useToast, Badge } from "../../components/ui";
import { PackageCheck, MapPin, Building, Phone, User, Camera, ArrowRight, CheckCircle2, Navigation } from "lucide-react";

const GOODS_CATEGORIES = ["Textiles", "FMCG", "Electronics", "Auto Spare Parts", "Pharma", "Furniture", "Industrial Fasteners"];

export default function SmeOnboarding() {
  const { refreshProfile, profile } = useAuth();
  const navigate = useNavigate();
  const toast = useToast();
  const [busy, setBusy] = useState(false);

  const getTempData = () => {
    try {
      const raw = localStorage.getItem("redo_signup_temp_data");
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  };

  const temp = getTempData();

  const [form, setForm] = useState({
    company_name: temp?.company_name || profile?.company_name || "",
    full_name: temp?.full_name || profile?.full_name || "",
    phone: temp?.phone || profile?.phone || "",
    city: temp?.city || "Mumbai",
    address: "",
    primary_category: temp?.category || "Textiles",
    gstin: "",
    avatar_url: profile?.avatar_url || "",
  });

  const [locating, setLocating] = useState(false);

  // Sync profile data if loaded asynchronously after registration
  useEffect(() => {
    const t = getTempData();
    if (profile || t) {
      setForm((prev) => ({
        ...prev,
        full_name: prev.full_name || t?.full_name || profile?.full_name || "",
        phone: prev.phone || t?.phone || profile?.phone || "",
        company_name: prev.company_name || t?.company_name || profile?.company_name || (profile?.full_name ? `${profile.full_name} Logistics` : ""),
        avatar_url: prev.avatar_url || profile?.avatar_url || "",
      }));
    }
  }, [profile]);

  // Rapido/Uber style auto-fetch live GPS location on page mount
  useEffect(() => {
    getLiveLocation();
  }, []);

  const getLiveLocation = () => {
    if (!navigator.geolocation) {
      toast("Geolocation is not supported by your browser.", "warn");
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        setForm((prev) => ({
          ...prev,
          address: `Live Location (${latitude.toFixed(4)}, ${longitude.toFixed(4)})`,
        }));
        toast("Live shipping location auto-detected!", "ok");
        setLocating(false);
      },
      () => {
        setForm((prev) => ({
          ...prev,
          address: prev.address || "Mumbai Industrial Hub, MIDC",
        }));
        setLocating(false);
      }
    );
  };

  const handleAvatarUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const url = URL.createObjectURL(file);
      setForm((prev) => ({ ...prev, avatar_url: url }));
      toast("Profile photo attached!", "ok");
    }
  };

  const submit = async () => {
    setBusy(true);
    try {
      const finalCompanyName = form.company_name.trim() || `${form.full_name || profile?.full_name || "Commercial"} Logistics`;
      const finalFullName = form.full_name.trim() || profile?.full_name || "SME Shipper";
      const finalPhone = form.phone.trim() || profile?.phone || "+91 98765 43210";

      const updateData = {
        company_name: finalCompanyName,
        full_name: finalFullName,
        phone: finalPhone,
        avatar_url: form.avatar_url,
        onboarding_complete: true,
      };

      if (profile?.id) {
        await supabase.from("profiles").update(updateData).eq("id", profile.id);
      }
      try {
        await api.patch("/auth/profile", updateData);
      } catch {}

      await refreshProfile();
      toast("SME Shipper Account Setup Complete!", "ok");
      navigate("/dashboard/sme");
    } catch (e: any) {
      toast(e.message || "Failed to complete setup.", "danger");
      navigate("/dashboard/sme");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between selection:bg-blue-600 selection:text-white">
      {/* Header */}
      <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-md sticky top-0 z-50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 h-16 flex items-center justify-between">
          <Logo dark />
          <Badge tone="accent">SME Shipper Registration</Badge>
        </div>
      </header>

      {/* Main Container */}
      <main className="flex-1 max-w-2xl w-full mx-auto px-4 py-8 sm:py-12">
        <Card className="!bg-slate-900 !border-slate-800 p-6 sm:p-8 space-y-6 shadow-2xl">
          <div className="flex items-center gap-3 border-b border-slate-800 pb-5">
            <div className="w-12 h-12 rounded-2xl bg-blue-500/10 border border-blue-500/20 text-blue-400 flex items-center justify-center">
              <PackageCheck className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-2xl font-black text-white">SME Shipper Profile & Shipping Criteria</h1>
              <p className="text-xs text-slate-400">Configure your business freight criteria and shipping location</p>
            </div>
          </div>

          {/* Profile DP Upload */}
          <div className="flex items-center gap-4 bg-slate-950 p-4 rounded-2xl border border-slate-800">
            <div className="w-16 h-16 rounded-2xl bg-blue-600 text-white font-black text-xl flex items-center justify-center overflow-hidden border border-slate-700 flex-shrink-0">
              {form.avatar_url ? (
                <img src={form.avatar_url} alt="Profile DP" className="w-full h-full object-cover" />
              ) : (
                (form.full_name || "S")[0].toUpperCase()
              )}
            </div>
            <div className="space-y-1">
              <span className="text-xs font-bold text-slate-200">Profile Photo / Logo (DP)</span>
              <label className="flex items-center gap-2 text-xs font-semibold text-blue-400 hover:text-blue-300 cursor-pointer">
                <Camera className="w-4 h-4" />
                <span>Upload Profile Picture</span>
                <input type="file" accept="image/*" className="hidden" onChange={handleAvatarUpload} />
              </label>
            </div>
          </div>

          <div className="space-y-4">
            <Field label="Business / Company Name">
              <input
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                value={form.company_name}
                onChange={(e) => setForm({ ...form, company_name: e.target.value })}
                placeholder="e.g. Apex Traders & Logistics"
              />
            </Field>

            <div className="grid sm:grid-cols-2 gap-4">
              <Field label="Contact Person">
                <input
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={form.full_name}
                  onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                  placeholder="Your Full Name"
                />
              </Field>

              <Field label="Mobile Phone">
                <input
                  type="tel"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={form.phone}
                  onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  placeholder="+91 98765 43210"
                />
              </Field>
            </div>

            {/* Live Location Access */}
            <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-200">Shipping Location Access</span>
                <button
                  type="button"
                  onClick={getLiveLocation}
                  disabled={locating}
                  className="flex items-center gap-1.5 px-3 py-1 rounded-xl bg-blue-600/20 text-blue-400 hover:bg-blue-600/30 text-xs font-bold transition"
                >
                  <Navigation className="w-3.5 h-3.5" />
                  <span>{locating ? "Detecting GPS…" : "Refetch Live Location"}</span>
                </button>
              </div>

              <input
                className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                value={form.address}
                onChange={(e) => setForm({ ...form, address: e.target.value })}
                placeholder="Warehouse Address / Pickup Landmark"
              />
            </div>

            {/* Freight Criteria */}
            <div className="grid sm:grid-cols-2 gap-4">
              <Field label="Primary Goods Category">
                <select
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={form.primary_category}
                  onChange={(e) => setForm({ ...form, primary_category: e.target.value })}
                >
                  {GOODS_CATEGORIES.map((g) => <option key={g}>{g}</option>)}
                </select>
              </Field>

              <Field label="GSTIN / Trade License (Optional)">
                <input
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  value={form.gstin}
                  onChange={(e) => setForm({ ...form, gstin: e.target.value })}
                  placeholder="e.g. 27AAAAA0000A1Z5"
                />
              </Field>
            </div>
          </div>

          <Button
            onClick={submit}
            disabled={busy}
            className="w-full !bg-blue-600 hover:!bg-blue-500 !text-white !py-3 !rounded-xl !font-bold shadow-lg shadow-blue-600/20 flex items-center justify-center gap-2"
          >
            <CheckCircle2 className="w-4 h-4" />
            <span>{busy ? "Saving Account Setup…" : "Complete Setup & Go to SME Dashboard"}</span>
          </Button>
        </Card>
      </main>

      <footer className="border-t border-slate-800/60 bg-slate-950 py-4">
        <div className="max-w-7xl mx-auto px-4 text-center text-xs text-slate-500">
          REDO Commercial Smart Backhaul Platform · Match. Consolidate. Track. Optimize.
        </div>
      </footer>
    </div>
  );
}

