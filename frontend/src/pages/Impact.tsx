import { useEffect, useState } from "react";
import Layout from "../components/Layout";
import { api } from "../services/api";
import { useAuth } from "../hooks/useAuth";
import { Card, CardSkeleton, EmptyState } from "../components/ui";

export default function Impact() {
  const [data, setData] = useState<any | null>(null);
  const { profile } = useAuth();
  useEffect(() => { api.get("/impact").then(setData).catch(() => setData({ records: 0, totals: {} })); }, []);

  if (!data) return <Layout><div className="grid gap-4 md:grid-cols-2"><CardSkeleton /><CardSkeleton /></div></Layout>;
  const t = data.totals || {};
  const items = profile?.role === "sme"
    ? [
        [`₹${Number(t.sme_saving_inr || 0).toLocaleString("en-IN")}`, "Estimated shipping saved"],
        [`${t.empty_km_avoided || 0} km`, "Empty km avoided"],
        [`${t.co2_avoided_kg || 0} kg`, "Estimated CO₂ avoided"],
        [`${t.fuel_avoided_liters || 0} L`, "Estimated fuel avoided"],
      ]
    : [
        [`₹${Number(t.truck_owner_income_inr || 0).toLocaleString("en-IN")}`, "Additional return income"],
        [`${t.empty_km_avoided || 0} km`, "Empty km avoided"],
        [`${t.avg_utilization_gain_pct || 0}%`, "Avg utilization gain"],
        [`${t.co2_avoided_kg || 0} kg`, "Estimated CO₂ avoided"],
      ];

  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Your impact</h1>
      <p className="text-sm text-ink-faint mt-1">
        Calculated from your {data.records} completed booking{data.records === 1 ? "" : "s"}. Fuel, CO₂ and savings figures are estimates.
      </p>
      {data.records === 0 ? (
        <div className="mt-6"><EmptyState title="No completed bookings yet." hint="Impact is generated automatically when a booking completes." /></div>
      ) : (
        <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {items.map(([v, l]) => (
            <Card key={l as string} className="p-5">
              <p className="text-2xl font-extrabold text-ink tabular-nums">{v}</p>
              <p className="mt-1 text-sm font-medium text-ink-faint">{l}</p>
            </Card>
          ))}
        </div>
      )}
    </Layout>
  );
}
