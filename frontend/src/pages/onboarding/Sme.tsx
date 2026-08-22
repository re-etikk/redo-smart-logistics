import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import { Logo } from "../../components/Layout";
import { Button, Card, Field, inputCls, useToast } from "../../components/ui";

export default function SmeOnboarding() {
  const [form, setForm] = useState({ company_name: "", full_name: "", phone: "" });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const { refreshProfile, profile } = useAuth();
  const navigate = useNavigate();
  const toast = useToast();

  const submit = async () => {
    setBusy(true); setError("");
    try {
      await api.patch("/auth/profile", {
        company_name: form.company_name,
        full_name: form.full_name || profile?.full_name,
        phone: form.phone || profile?.phone,
        onboarding_complete: true,
      });
      await refreshProfile();
      toast("Business profile saved");
      navigate("/dashboard/sme");
    } catch (e: any) { setError(e.message); setBusy(false); }
  };

  return (
    <div className="min-h-screen bg-canvas">
      <header className="bg-white border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center"><Logo /></div>
      </header>
      <main className="mx-auto max-w-lg px-4 py-8">
        <p className="text-xs font-semibold uppercase tracking-wide text-ink-faint">Step 1 of 1 · Business details</p>
        <Card className="mt-3 p-6 space-y-4">
          <Field label="Business name"><input className={inputCls} value={form.company_name} onChange={(e) => setForm({ ...form, company_name: e.target.value })} /></Field>
          <Field label="Contact person"><input className={inputCls} value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} placeholder={profile?.full_name} /></Field>
          <Field label="Phone" error={error}><input className={inputCls} value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} placeholder={profile?.phone} /></Field>
          <Button className="w-full" onClick={submit} disabled={busy || !form.company_name}>Save and continue</Button>
        </Card>
      </main>
    </div>
  );
}
