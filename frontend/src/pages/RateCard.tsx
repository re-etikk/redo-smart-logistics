import { useEffect, useMemo, useState } from "react";
import { Download, Info } from "lucide-react";
import Layout from "../components/Layout";
import { api } from "../services/api";
import { Button, Card, CardSkeleton, Field, SectionHead, Tabs, inputCls, useToast } from "../components/ui";

interface Rate { origin: string; destination: string; distance_km: number;
  ft20: number; ft24: number; ft32: number; ft40: number; transit_days: string; }

export default function RateCard() {
  const [rates, setRates] = useState<Rate[] | null>(null);
  const [tab, setTab] = useState("ftl");
  const [calc, setCalc] = useState({ origin: "", destination: "", vehicle: "ft32" });
  const [result, setResult] = useState<number | null>(null);
  const toast = useToast();

  useEffect(() => { api.get<Rate[]>("/rates").then(setRates).catch(() => setRates([])); }, []);

  const cities = useMemo(() => [...new Set((rates ?? []).flatMap((r) => [r.origin, r.destination]))], [rates]);

  const getRates = () => {
    const row = (rates ?? []).find((r) => r.origin === calc.origin && r.destination === calc.destination);
    if (!row) { toast("No published rate for this lane — request a custom quote.", "warn"); setResult(null); return; }
    setResult((row as any)[calc.vehicle]);
  };

  return (
    <Layout>
      <SectionHead title="Rate Card" sub="Transparent pricing for Full Truck Load (FTL) and Part Load (LTL) shipments." />
      <Card className="mt-5 p-5">
        <Tabs active={tab} onChange={setTab} tabs={[
          { key: "ftl", label: "FTL (Full Truck Load)" }, { key: "ltl", label: "Part Load (LTL)" },
          { key: "fees", label: "Surcharges & Fees" },
        ]} />

        {tab === "ftl" && (<>
          <div className="mt-4 grid sm:grid-cols-4 gap-3 items-end">
            <Field label="From Location">
              <select className={inputCls} value={calc.origin} onChange={(e) => setCalc({ ...calc, origin: e.target.value })}>
                <option value="">Select city</option>{cities.map((c) => <option key={c}>{c}</option>)}
              </select>
            </Field>
            <Field label="To Location">
              <select className={inputCls} value={calc.destination} onChange={(e) => setCalc({ ...calc, destination: e.target.value })}>
                <option value="">Select city</option>{cities.map((c) => <option key={c}>{c}</option>)}
              </select>
            </Field>
            <Field label="Vehicle Type">
              <select className={inputCls} value={calc.vehicle} onChange={(e) => setCalc({ ...calc, vehicle: e.target.value })}>
                <option value="ft20">20 FT</option><option value="ft24">24 FT</option>
                <option value="ft32">32 FT</option><option value="ft40">40 FT</option>
              </select>
            </Field>
            <Button onClick={getRates} disabled={!calc.origin || !calc.destination}>Get Rates →</Button>
          </div>
          {result !== null && (
            <p className="mt-3 rounded-lg bg-accent-soft px-4 py-3 text-sm font-bold text-ink">
              Indicative rate: ₹{result.toLocaleString("en-IN")} <span className="font-medium text-ink-soft">(excl. GST)</span>
            </p>
          )}
          <div className="mt-3 flex items-start gap-2 rounded-lg bg-info-soft px-4 py-2.5 text-xs text-ink-soft">
            <Info size={14} className="text-info shrink-0 mt-0.5" />
            Prices are indicative and may vary based on weight, dimensions, commodity and availability.
          </div>

          <div className="mt-5 flex items-center justify-between">
            <h2 className="font-bold text-ink">Popular Lane Rates (FTL)</h2>
            <button className="inline-flex items-center gap-1.5 text-sm font-semibold text-accent"
              onClick={() => window.print()}><Download size={15} /> Download Full Rate Card</button>
          </div>
          {rates === null ? <div className="mt-3"><CardSkeleton /></div> : (
            <div className="mt-3 overflow-x-auto">
              <table className="w-full text-sm min-w-[720px]">
                <thead><tr className="text-left text-xs font-semibold text-ink-faint border-b border-line">
                  <th className="py-2.5 pr-3">Origin</th><th className="py-2.5 pr-3">Destination</th>
                  <th className="py-2.5 pr-3">Distance (km)</th><th className="py-2.5 pr-3">20 FT</th>
                  <th className="py-2.5 pr-3">24 FT</th><th className="py-2.5 pr-3">32 FT</th>
                  <th className="py-2.5 pr-3">40 FT</th><th className="py-2.5">Transit Time</th>
                </tr></thead>
                <tbody>
                  {rates.map((r) => (
                    <tr key={r.origin + r.destination} className="border-b border-line last:border-0">
                      <td className="py-3 pr-3 font-semibold">{r.origin}</td>
                      <td className="py-3 pr-3 font-semibold">{r.destination}</td>
                      <td className="py-3 pr-3 text-ink-soft tabular-nums">{r.distance_km.toLocaleString("en-IN")}</td>
                      {(["ft20", "ft24", "ft32", "ft40"] as const).map((k) => (
                        <td key={k} className="py-3 pr-3 tabular-nums">₹{r[k].toLocaleString("en-IN")}</td>
                      ))}
                      <td className="py-3 text-ink-soft">{r.transit_days}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <p className="mt-3 text-xs text-ink-faint">Rates are exclusive of GST. Applicable taxes will be added at checkout.</p>
            </div>
          )}
        </>)}

        {tab === "ltl" && (
          <p className="mt-5 text-sm text-ink-soft max-w-lg">
            Part-load (backhaul) pricing is dynamic: it comes from each truck owner&apos;s per-km-per-tonne rate on their return trip.
            Post a shipment from <span className="font-semibold">Book Shipment</span> to see live LTL quotes on matched trucks.
          </p>
        )}
        {tab === "fees" && (
          <dl className="mt-5 max-w-md divide-y divide-line text-sm">
            {[["Loading / unloading assistance", "₹500 – ₹1,500 per point"], ["Insurance (optional)", "0.3% of declared value"],
              ["Waiting charges", "₹300 / hour after 2 free hours"], ["Cancellation after confirmation", "5% of booking value"]]
              .map(([k, v]) => (
                <div key={k} className="flex justify-between py-2.5"><dt className="text-ink-soft">{k}</dt><dd className="font-semibold">{v}</dd></div>
              ))}
          </dl>
        )}
      </Card>
    </Layout>
  );
}
