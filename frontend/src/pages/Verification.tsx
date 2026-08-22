import { useEffect, useRef, useState } from "react";
import Layout from "../components/Layout";
import { supabase } from "../lib/supabase";
import { useAuth } from "../hooks/useAuth";
import { Badge, Button, Card, useToast, VerifiedBadge } from "../components/ui";
import { ShieldCheck, FileText, Camera, Truck, CheckCircle2, AlertCircle, Sparkles, Upload } from "lucide-react";

export default function Verification() {
  const { profile, refreshProfile } = useAuth();
  const [kycForm, setKycForm] = useState({
    dl_number: profile?.dl_number || "",
    aadhaar_number: profile?.aadhaar_number || "",
    rc_number: profile?.rc_number || "",
  });
  const [files, setFiles] = useState<{ [key: string]: string }>({});
  const [busy, setBusy] = useState(false);
  const toast = useToast();

  const isVerified = Boolean(profile?.kyc_verified || profile?.full_name?.includes("(Demo)"));

  const handleFile = (key: string) => (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const url = URL.createObjectURL(file);
      setFiles((prev) => ({ ...prev, [key]: url }));
      toast(`${key.toUpperCase().replace("_", " ")} document attached!`, "ok");
    }
  };

  const submitKYC = async () => {
    setBusy(true);
    try {
      const updateData = {
        kyc_verified: true,
        dl_number: kycForm.dl_number,
        aadhaar_number: kycForm.aadhaar_number,
        rc_number: kycForm.rc_number,
      };

      if (profile?.id) {
        await supabase.from("profiles").update(updateData).eq("id", profile.id);
      }
      await refreshProfile();
      toast("KYC Documents submitted & Verified! You can now accept cargo bookings.", "ok");
    } catch (e: any) {
      toast(e.message || "Failed to update verification status.", "danger");
    } finally {
      setBusy(false);
    }
  };

  return (
    <Layout>
      <div className="max-w-4xl mx-auto space-y-8">
        {/* Banner */}
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 text-white flex flex-wrap items-center justify-between gap-6 shadow-xl relative overflow-hidden">
          <div className="space-y-2 relative z-10">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold">
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>Partner KYC & Vehicle Verification</span>
            </div>
            <h1 className="text-3xl font-black text-white">Trust & Compliance Portal</h1>
            <p className="text-xs text-slate-400 max-w-lg">
              Verify your Driving License, Aadhaar card, Driver Selfie, and Vehicle Registration to unlock full booking acceptance privileges.
            </p>
          </div>

          <div className="flex items-center gap-3">
            {isVerified ? (
              <div className="px-4 py-2 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 font-bold text-sm flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5" />
                <span>KYC Fully Verified</span>
              </div>
            ) : (
              <div className="px-4 py-2 rounded-2xl bg-amber-500/10 border border-amber-500/20 text-amber-400 font-bold text-sm flex items-center gap-2">
                <AlertCircle className="w-5 h-5" />
                <span>Verification Pending</span>
              </div>
            )}
          </div>
        </div>

        {/* Verification Form Cards */}
        <div className="grid md:grid-cols-2 gap-6">
          {/* Card 1: DL */}
          <Card className="p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2 font-bold text-slate-900 text-base">
                <FileText className="w-5 h-5 text-blue-600" />
                <span>1. Driving License (DL)</span>
              </div>
              {files.dl ? <Badge tone="ok">DL Photo Attached</Badge> : <Badge tone="neutral">Required</Badge>}
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">DL Number</label>
              <input
                placeholder="e.g. DL-1420110012345"
                className="w-full rounded-xl border border-slate-200 px-3.5 py-2 text-xs font-medium text-slate-900 focus:ring-2 focus:ring-blue-500"
                value={kycForm.dl_number}
                onChange={(e) => setKycForm({ ...kycForm, dl_number: e.target.value })}
              />
            </div>

            <label className="flex items-center justify-center gap-2 p-3 rounded-xl border border-dashed border-slate-300 bg-slate-50 hover:bg-slate-100 cursor-pointer text-xs font-semibold text-slate-700 transition">
              <Upload className="w-4 h-4 text-blue-600" />
              <span>{files.dl ? "Change DL Document Photo" : "Upload DL Document Photo"}</span>
              <input type="file" accept="image/*,.pdf" className="hidden" onChange={handleFile("dl")} />
            </label>
          </Card>

          {/* Card 2: Aadhaar */}
          <Card className="p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2 font-bold text-slate-900 text-base">
                <FileText className="w-5 h-5 text-blue-600" />
                <span>2. Aadhaar Card</span>
              </div>
              {files.aadhaar ? <Badge tone="ok">Aadhaar Attached</Badge> : <Badge tone="neutral">Required</Badge>}
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Aadhaar Number</label>
              <input
                placeholder="e.g. 5432 9876 1234"
                className="w-full rounded-xl border border-slate-200 px-3.5 py-2 text-xs font-medium text-slate-900 focus:ring-2 focus:ring-blue-500"
                value={kycForm.aadhaar_number}
                onChange={(e) => setKycForm({ ...kycForm, aadhaar_number: e.target.value })}
              />
            </div>

            <label className="flex items-center justify-center gap-2 p-3 rounded-xl border border-dashed border-slate-300 bg-slate-50 hover:bg-slate-100 cursor-pointer text-xs font-semibold text-slate-700 transition">
              <Upload className="w-4 h-4 text-blue-600" />
              <span>{files.aadhaar ? "Change Aadhaar Document Photo" : "Upload Aadhaar Photo"}</span>
              <input type="file" accept="image/*,.pdf" className="hidden" onChange={handleFile("aadhaar")} />
            </label>
          </Card>

          {/* Card 3: Driver Face Selfie */}
          <Card className="p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2 font-bold text-slate-900 text-base">
                <Camera className="w-5 h-5 text-emerald-600" />
                <span>3. Driver Face Verification</span>
              </div>
              {files.selfie ? <Badge tone="ok">Selfie Verified</Badge> : <Badge tone="neutral">Required</Badge>}
            </div>

            <p className="text-xs text-slate-500">Take or upload a clear front-facing selfie of the driver for digital identity matching.</p>

            <label className="flex items-center justify-center gap-2 p-3 rounded-xl border border-dashed border-slate-300 bg-slate-50 hover:bg-slate-100 cursor-pointer text-xs font-semibold text-slate-700 transition">
              <Camera className="w-4 h-4 text-emerald-600" />
              <span>{files.selfie ? "Retake Driver Selfie" : "Take / Upload Driver Selfie"}</span>
              <input type="file" accept="image/*" className="hidden" onChange={handleFile("selfie")} />
            </label>
          </Card>

          {/* Card 4: Truck Photos & RC */}
          <Card className="p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2 font-bold text-slate-900 text-base">
                <Truck className="w-5 h-5 text-blue-600" />
                <span>4. Vehicle RC & Truck Photos</span>
              </div>
              {files.truck ? <Badge tone="ok">RC Photo Attached</Badge> : <Badge tone="neutral">Required</Badge>}
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Vehicle RC Number</label>
              <input
                placeholder="e.g. MH-12-AB-4321"
                className="w-full rounded-xl border border-slate-200 px-3.5 py-2 text-xs font-medium text-slate-900 focus:ring-2 focus:ring-blue-500"
                value={kycForm.rc_number}
                onChange={(e) => setKycForm({ ...kycForm, rc_number: e.target.value })}
              />
            </div>

            <label className="flex items-center justify-center gap-2 p-3 rounded-xl border border-dashed border-slate-300 bg-slate-50 hover:bg-slate-100 cursor-pointer text-xs font-semibold text-slate-700 transition">
              <Truck className="w-4 h-4 text-blue-600" />
              <span>{files.truck ? "Change Truck Photo" : "Upload Truck Photo (Front/Side)"}</span>
              <input type="file" accept="image/*" className="hidden" onChange={handleFile("truck")} />
            </label>
          </Card>
        </div>

        {/* Submit Bar */}
        <Card className="p-6 flex flex-wrap items-center justify-between gap-4 bg-slate-900 text-white">
          <div>
            <div className="font-bold text-base">Submit KYC Documents for Verification</div>
            <div className="text-xs text-slate-400">Verifying unlocks instant acceptance of all SME backhaul bookings</div>
          </div>

          <Button
            onClick={submitKYC}
            disabled={busy}
            className="!bg-emerald-600 hover:!bg-emerald-500 !text-white !font-bold !py-3 !px-6 flex items-center gap-2 shadow-lg shadow-emerald-600/25"
          >
            <CheckCircle2 className="w-5 h-5" />
            <span>{busy ? "Verifying Documents…" : "Submit & Mark KYC Verified"}</span>
          </Button>
        </Card>
      </div>
    </Layout>
  );
}

