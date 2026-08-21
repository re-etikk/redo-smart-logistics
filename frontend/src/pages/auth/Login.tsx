import { useState, type FormEvent } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { supabase } from "../../lib/supabase";
import { useAuth } from "../../hooks/useAuth";
import { Logo } from "../../components/Layout";
import { Button, Card, Field, inputCls } from "../../components/ui";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const location = useLocation() as any;
  const { refreshProfile } = useAuth();

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true); setError("");
    const { error: err } = await supabase.auth.signInWithPassword({ email, password });
    if (err) { setError("Incorrect email or password."); setBusy(false); return; }
    await refreshProfile();
    const { data } = await supabase.auth.getSession();
    const uid = data.session?.user.id;
    const { data: profile } = await supabase.from("profiles").select("role, onboarding_complete").eq("id", uid).single();
    if (!profile) navigate("/signup");
    else if (!profile.onboarding_complete) navigate(profile.role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
    else navigate(location.state?.from || (profile.role === "sme" ? "/dashboard/sme" : "/dashboard/owner"));
  };

  return (
    <div className="min-h-screen bg-canvas flex flex-col">
      <header className="bg-white border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center"><Link to="/"><Logo /></Link></div>
      </header>
      <main className="flex-1 grid place-items-center px-4 py-10">
        <Card className="w-full max-w-sm p-6">
          <h1 className="text-xl font-extrabold text-ink">Sign in</h1>
          <form className="mt-5 space-y-4" onSubmit={submit}>
            <Field label="Email">
              <input type="email" required className={inputCls} value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" />
            </Field>
            <Field label="Password" error={error}>
              <input type="password" required className={inputCls} value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
            </Field>
            <Button className="w-full" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</Button>
          </form>
          <div className="mt-4 flex justify-between text-sm">
            <Link to="/forgot-password" className="font-semibold text-accent">Forgot password</Link>
            <Link to="/signup" className="font-semibold text-accent">Create account</Link>
          </div>
          <p className="mt-5 text-xs text-ink-faint border-t border-line pt-4">
            Demo accounts (real authenticated sessions): <span className="font-semibold">demo.owner@redo.app</span> and{" "}
            <span className="font-semibold">demo.sme@redo.app</span> — password set by your event organiser.
          </p>
        </Card>
      </main>
    </div>
  );
}
