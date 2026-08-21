import { useState, type ChangeEvent, type FormEvent } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { supabase } from "../../lib/supabase";
import { api } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import { Logo } from "../../components/Layout";
import { Button, Card, Field, inputCls } from "../../components/ui";
import type { Role } from "../../lib/types";

export default function SignUp() {
  const [params] = useSearchParams();
  const [role, setRole] = useState<Role | null>((params.get("role") as Role) || null);
  const [form, setForm] = useState({ full_name: "", email: "", password: "", phone: "" });
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const { refreshProfile } = useAuth();
  const set = (k: string) => (e: ChangeEvent<HTMLInputElement>) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!role) return;
    setBusy(true); setError("");
    const { error: err } = await supabase.auth.signUp({ email: form.email, password: form.password });
    if (err) { setError(err.message); setBusy(false); return; }
    // If email confirmation is enabled the session may be null — sign in directly for local/dev.
    await supabase.auth.signInWithPassword({ email: form.email, password: form.password }).catch(() => {});
    try {
      await api.post("/auth/profile", { full_name: form.full_name, phone: form.phone, role });
    } catch (e2: any) { setError(e2.message); setBusy(false); return; }
    await refreshProfile();
    navigate(role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
  };

  return (
    <div className="min-h-screen bg-canvas flex flex-col">
      <header className="bg-white border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center"><Link to="/"><Logo /></Link></div>
      </header>
      <main className="flex-1 grid place-items-center px-4 py-10">
        {!role ? (
          <div className="w-full max-w-2xl">
            <h1 className="text-2xl font-extrabold text-ink text-center">How will you use Redo?</h1>
            <div className="mt-8 grid sm:grid-cols-2 gap-4">
              <Card hover className="p-6">
                <h2 className="font-bold text-ink">I have a truck</h2>
                <p className="mt-1 text-sm text-ink-soft">Earn from unused return capacity.</p>
                <Button className="mt-5 w-full" onClick={() => setRole("truck_owner")}>Continue as truck owner</Button>
              </Card>
              <Card hover className="p-6">
                <h2 className="font-bold text-ink">I have cargo</h2>
                <p className="mt-1 text-sm text-ink-soft">Ship partial loads affordably.</p>
                <Button className="mt-5 w-full" onClick={() => setRole("sme")}>Continue as shipper</Button>
              </Card>
            </div>
          </div>
        ) : (
          <Card className="w-full max-w-sm p-6">
            <h1 className="text-xl font-extrabold text-ink">Create account</h1>
            <p className="text-sm text-ink-faint mt-0.5">{role === "sme" ? "SME / Shipper" : "Truck owner"} ·{" "}
              <button className="text-accent font-semibold" onClick={() => setRole(null)}>change</button></p>
            <form className="mt-5 space-y-4" onSubmit={submit}>
              <Field label="Full name"><input required className={inputCls} value={form.full_name} onChange={set("full_name")} /></Field>
              <Field label="Email"><input type="email" required className={inputCls} value={form.email} onChange={set("email")} /></Field>
              <Field label="Phone"><input type="tel" required className={inputCls} value={form.phone} onChange={set("phone")} /></Field>
              <Field label="Password" error={error}>
                <input type="password" required minLength={8} className={inputCls} value={form.password} onChange={set("password")} />
              </Field>
              <Button className="w-full" disabled={busy}>{busy ? "Creating account…" : "Create account"}</Button>
            </form>
            <p className="mt-4 text-sm text-ink-faint">Already have an account?{" "}
              <Link to="/login" className="font-semibold text-accent">Sign in</Link></p>
          </Card>
        )}
      </main>
    </div>
  );
}
