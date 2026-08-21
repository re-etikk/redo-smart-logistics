import { useState } from "react";
import Layout from "../components/Layout";
import { api } from "../services/api";
import { useAuth } from "../hooks/useAuth";
import { Button, Card, Field, inputCls, useToast } from "../components/ui";

export default function Profile() {
  const { profile, refreshProfile } = useAuth();
  const [form, setForm] = useState({ full_name: profile?.full_name || "", phone: profile?.phone || "", company_name: profile?.company_name || "" });
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const save = async () => {
    setBusy(true);
    try { await api.patch("/auth/profile", form); await refreshProfile(); toast("Profile saved"); }
    catch (e: any) { toast(e.message, "danger"); } finally { setBusy(false); }
  };
  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Profile</h1>
      <Card className="mt-6 max-w-lg p-6 space-y-4">
        <Field label="Full name"><input className={inputCls} value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} /></Field>
        <Field label="Phone"><input className={inputCls} value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} /></Field>
        <Field label="Company"><input className={inputCls} value={form.company_name} onChange={(e) => setForm({ ...form, company_name: e.target.value })} /></Field>
        <p className="text-xs text-ink-faint">Role: <span className="font-semibold">{profile?.role === "sme" ? "SME / Shipper" : "Truck owner"}</span></p>
        <Button onClick={save} disabled={busy}>{busy ? "Saving…" : "Save changes"}</Button>
      </Card>
    </Layout>
  );
}
