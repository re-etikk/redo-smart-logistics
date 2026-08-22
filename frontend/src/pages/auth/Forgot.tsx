import { useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { supabase } from "../../lib/supabase";
import { Logo } from "../../components/Layout";
import { Button, Card, Field, inputCls } from "../../components/ui";

export default function Forgot() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    // Real Supabase reset email (spec §10) — no fake success screens.
    const { error: err } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: window.location.origin + "/login",
    });
    if (err) setError(err.message); else setSent(true);
  };

  return (
    <div className="min-h-screen bg-canvas flex flex-col">
      <header className="bg-white border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center"><Link to="/"><Logo /></Link></div>
      </header>
      <main className="flex-1 grid place-items-center px-4">
        <Card className="w-full max-w-sm p-6">
          <h1 className="text-xl font-extrabold text-ink">Reset password</h1>
          {sent ? (
            <p className="mt-4 text-sm text-ink-soft">
              If an account exists for <span className="font-semibold">{email}</span>, a reset link has been sent.
            </p>
          ) : (
            <form className="mt-5 space-y-4" onSubmit={submit}>
              <Field label="Email" error={error}>
                <input type="email" required className={inputCls} value={email} onChange={(e) => setEmail(e.target.value)} />
              </Field>
              <Button className="w-full">Send reset link</Button>
            </form>
          )}
          <p className="mt-4 text-sm"><Link to="/login" className="font-semibold text-accent">Back to sign in</Link></p>
        </Card>
      </main>
    </div>
  );
}
