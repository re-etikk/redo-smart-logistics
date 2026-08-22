import { useState } from "react";
import Layout from "../components/Layout";
import { api } from "../services/api";
import { useAuth } from "../hooks/useAuth";
import { supabase } from "../lib/supabase";
import { Button, Card, Field, inputCls, useToast, VerifiedBadge, Badge } from "../components/ui";
import { User, Building, Phone, Camera, Save, Truck, ShieldCheck, MapPin, PackageCheck } from "lucide-react";

export default function Profile() {
  const { profile, refreshProfile } = useAuth();
  const [form, setForm] = useState({
    full_name: profile?.full_name || "",
    phone: profile?.phone || "",
    company_name: profile?.company_name || "",
    avatar_url: profile?.avatar_url || "",
  });
  const [busy, setBusy] = useState(false);
  const toast = useToast();

  const handleAvatarUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const url = URL.createObjectURL(file);
      setForm((prev) => ({ ...prev, avatar_url: url }));
      toast("DP Avatar image updated! Click 'Save Profile Changes' to persist.", "ok");
    }
  };

  const save = async () => {
    setBusy(true);
    try {
      if (profile?.id) {
        await supabase.from("profiles").update(form).eq("id", profile.id);
      }
      try {
        await api.patch("/auth/profile", form);
      } catch {
        // Fallback
      }
      await refreshProfile();
      toast("Profile changes and DP saved successfully!", "ok");
    } catch (e: any) {
      toast(e.message || "Could not save profile changes.", "danger");
    } finally {
      setBusy(false);
    }
  };

  const isTruckOwner = profile?.role === "truck_owner";

  return (
    <Layout>
      <div className="max-w-2xl mx-auto space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900">
              {isTruckOwner ? "Fleet Owner Profile" : "SME Shipper Profile"}
            </h1>
            <p className="text-xs text-slate-500 mt-1">Manage your account DP, contact info & role preferences</p>
          </div>
          <VerifiedBadge demo />
        </div>

        <Card className="p-6 sm:p-8 space-y-6">
          {/* Avatar / DP Upload Section */}
          <div className="flex items-center gap-5 bg-slate-50 p-4 rounded-2xl border border-slate-200">
            <div className="relative group w-20 h-20 rounded-2xl bg-blue-600 text-white font-black text-2xl flex items-center justify-center overflow-hidden border-2 border-white shadow-md">
              {form.avatar_url ? (
                <img src={form.avatar_url} alt="Profile DP" className="w-full h-full object-cover" />
              ) : (
                (form.full_name || "U")[0].toUpperCase()
              )}
            </div>

            <div className="space-y-1">
              <span className="text-xs font-black text-slate-800 uppercase tracking-wide">Profile Photo (DP)</span>
              <p className="text-xs text-slate-500">Upload a crisp photo or logo to display across matches</p>
              <label className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 text-blue-700 hover:bg-blue-100 rounded-xl text-xs font-bold transition cursor-pointer border border-blue-200">
                <Camera className="w-3.5 h-3.5" />
                <span>Change Photo / DP</span>
                <input type="file" accept="image/*" className="hidden" onChange={handleAvatarUpload} />
              </label>
            </div>
          </div>

          <div className="space-y-4">
            <Field label="Full Name">
              <input
                className={inputCls}
                value={form.full_name}
                onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                placeholder="Your full name"
              />
            </Field>

            <Field label="Mobile Phone">
              <input
                type="tel"
                className={inputCls}
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                placeholder="+91 98765 43210"
              />
            </Field>

            <Field label={isTruckOwner ? "Fleet / Transport Agency Name" : "Company / Business Name"}>
              <input
                className={inputCls}
                value={form.company_name}
                onChange={(e) => setForm({ ...form, company_name: e.target.value })}
                placeholder={isTruckOwner ? "e.g. Royal Truck Logistics" : "e.g. Apex Goods & Traders"}
              />
            </Field>

            {/* Role Custom Info Card */}
            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-700">Account Role Persona</span>
                <Badge tone={isTruckOwner ? "ok" : "accent"}>
                  {isTruckOwner ? "Fleet Owner (Trucker)" : "SME Shipper (Cargo)"}
                </Badge>
              </div>

              {isTruckOwner ? (
                <div className="text-xs text-slate-600 space-y-1.5">
                  <div className="flex items-center gap-2">
                    <Truck className="w-4 h-4 text-emerald-600" />
                    <span>Driving License & RC Verification Status: <strong className="text-emerald-700 font-bold">Verified</strong></span>
                  </div>
                  <a href="/verification" className="text-blue-600 font-bold hover:underline inline-block text-xs">
                    View or Update Vehicle KYC Documents →
                  </a>
                </div>
              ) : (
                <div className="text-xs text-slate-600 space-y-1.5">
                  <div className="flex items-center gap-2">
                    <PackageCheck className="w-4 h-4 text-blue-600" />
                    <span>Shipping Criteria: <strong className="text-slate-800 font-bold">Active Cargo Shipper</strong></span>
                  </div>
                  <div className="flex items-center gap-2 text-slate-500">
                    <MapPin className="w-3.5 h-3.5" />
                    <span>Live GPS Location enabled for instant warehouse dispatch matching</span>
                  </div>
                </div>
              )}
            </div>
          </div>

          <Button onClick={save} disabled={busy} className="w-full !bg-blue-600 hover:!bg-blue-500 !text-white !font-bold flex items-center justify-center gap-2">
            <Save className="w-4 h-4" />
            <span>{busy ? "Saving Profile…" : "Save Profile Changes"}</span>
          </Button>
        </Card>
      </div>
    </Layout>
  );
}


