import { useEffect, useState } from "react";
import Layout from "../components/Layout";
import { api } from "../services/api";
import { Badge, Card } from "../components/ui";

// Development-only diagnostics (§76). Route is registered only when import.meta.env.DEV.
export default function Diagnostics() {
  const [d, setD] = useState<any | null>(null);
  useEffect(() => { api.get("/diagnostics").then(setD).catch(() => setD({ backend: "down" })); }, []);
  const row = (label: string, v?: string) => (
    <div className="flex items-center justify-between py-2 border-b border-line last:border-0">
      <span className="text-sm font-semibold text-ink">{label}</span>
      <Badge tone={v?.startsWith("connected") ? "ok" : "danger"}>{v ?? "checking…"}</Badge>
    </div>
  );
  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Diagnostics <span className="text-sm font-semibold text-ink-faint">(dev only)</span></h1>
      <Card className="mt-6 max-w-md p-5">
        {row("Backend", d?.backend)}
        {row("Supabase", d?.supabase)}
        {row("ML service", d?.ml_service)}
      </Card>
    </Layout>
  );
}
