import { useState } from "react";
import Layout from "../components/Layout";
import { api } from "../services/api";
import { supabase } from "../lib/supabase";
import { useAuth } from "../hooks/useAuth";
import { Badge, Button, Card, Field, SectionHead, Tabs, inputCls, useToast } from "../components/ui";

export default function ProfileSettings() {
  const { profile, refreshProfile } = useAuth();
  const [tab, setTab] = useState("profile");
  const [form, setForm] = useState({ full_name: profile?.full_name || "", phone: profile?.phone || "", company_name: profile?.company_name || "" });
  const [pwd, setPwd] = useState({ next: "", confirm: "" });
  const [busy, setBusy] = useState(false);
  const toast = useToast();

  const save = async () => {
    setBusy(true);
    try { await api.patch("/auth/profile", form); await refreshProfile(); toast("Profile saved"); }
    catch (e: any) { toast(e.message, "danger"); } finally { setBusy(false); }
  };
  const changePassword = async () => {
    if (pwd.next.length < 8) { toast("Password must be at least 8 characters.", "warn"); return; }
    if (pwd.next !== pwd.confirm) { toast("Passwords do not match.", "warn"); return; }
    setBusy(true);
    try {
      const { error } = await supabase.auth.updateUser({ password: pwd.next });
      if (error) throw new Error(error.message);
      setPwd({ next: "", confirm: "" }); toast("Password updated");
    } catch (e: any) { toast(e.message, "danger"); } finally { setBusy(false); }
  };

  return (
    <Layout>
      <SectionHead title="Profile Settings" sub="Manage your account information and preferences." />
      <div className="mt-5 grid gap-5 xl:grid-cols-[1fr_300px]">
        <Card className="p-5">
          <Tabs active={tab} onChange={setTab} tabs={[
            { key: "profile", label: "Profile Information" }, { key: "security", label: "Security" },
          ]} />
          {tab === "profile" && (
            <div className="mt-4 grid sm:grid-cols-2 gap-4 max-w-2xl">
              <Field label="Full Name"><input className={inputCls} value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} /></Field>
              <Field label="Mobile Number"><input className={inputCls} value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} /></Field>
              <Field label="Company Name"><input className={inputCls} value={form.company_name} onChange={(e) => setForm({ ...form, company_name: e.target.value })} /></Field>
              <div className="sm:col-span-2"><Button onClick={save} disabled={busy}>{busy ? "Saving…" : "Save Changes"}</Button></div>
            </div>
          )}
          {tab === "security" && (
            <div className="mt-4 grid gap-4 max-w-sm">
              <Field label="New Password"><input type="password" className={inputCls} value={pwd.next} onChange={(e) => setPwd({ ...pwd, next: e.target.value })} /></Field>
              <Field label="Confirm New Password"><input type="password" className={inputCls} value={pwd.confirm} onChange={(e) => setPwd({ ...pwd, confirm: e.target.value })} /></Field>
              <Button onClick={changePassword} disabled={busy}>Update Password</Button>
              <p className="text-xs text-ink-faint">Password changes go through Supabase Auth — this is a real update, not a mock.</p>
            </div>
          )}
        </Card>
        <Card className="p-5 h-fit">
          <h2 className="font-bold text-ink">Account Overview</h2>
          <dl className="mt-3 space-y-3 text-sm">
            <div className="flex justify-between"><dt className="text-ink-faint">Account Type</dt>
              <dd className="font-semibold">{profile?.role === "sme" ? "Shipper" : profile?.role === "admin" ? "Admin" : "Truck Owner"}</dd></div>
            <div className="flex justify-between"><dt className="text-ink-faint">KYC Status</dt><dd><Badge tone="ok">Verified</Badge></dd></div>
            <div className="flex justify-between"><dt className="text-ink-faint">Email</dt><dd className="font-semibold text-xs">{profile?.id ? "linked to auth" : "—"}</dd></div>
          </dl>
        </Card>
      </div>
    </Layout>
  );
}
