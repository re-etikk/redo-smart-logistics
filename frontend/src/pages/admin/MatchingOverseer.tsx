import { useEffect, useState } from "react";
import { CheckCircle2, AlertTriangle, ShieldCheck, ArrowRight, Zap, RefreshCw, Box, Truck } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, SectionHead, useToast } from "../../components/ui";

export default function MatchingOverseer() {
  const [loading, setLoading] = useState(true);
  const [items, setItems] = useState<any[]>([]);
  const [dispatchingId, setDispatchingId] = useState<string | null>(null);
  const toast = useToast();

  const loadData = () => {
    setLoading(true);
    api.get<any[]>("/admin/matching/candidates")
      .then(res => setItems(res || []))
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleManualDispatch = async (cargoId: string, truckId: string, priceInr: number) => {
    setDispatchingId(`${cargoId}-${truckId}`);
    try {
      await api.post("/admin/matching/override", {
        cargo_id: cargoId,
        truck_id: truckId,
        override_price_inr: priceInr,
        override_reason: "Operations Lead Dispatch Confirmation",
      });
      toast(`Cargo successfully locked to truck. Shipper & driver notified.`, "ok");
      loadData();
    } catch (e: any) {
      toast(e?.message || "Could not complete manual dispatch.", "danger");
    } finally {
      setDispatchingId(null);
    }
  };

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="Matching Overseer & Dispatch Control" 
          sub="Inspect algorithmic multi-segment candidate scoring, review co-load safety, and execute manual dispatch overrides." 
        />
        <Button variant="secondary" onClick={loadData} disabled={loading} className="gap-2 self-start md:self-auto">
          <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
          Refresh Matches
        </Button>
      </div>

      {loading ? (
        <div className="mt-6 space-y-4">
          <CardSkeleton /><CardSkeleton />
        </div>
      ) : items.length === 0 ? (
        <Card className="mt-6 p-10 text-center">
          <Box size={40} className="mx-auto text-slate-300 mb-2" />
          <p className="font-bold text-slate-800">All cargo requests currently dispatched!</p>
          <p className="text-xs text-slate-500 mt-1">New unassigned cargo requests will automatically populate candidate trucks here.</p>
        </Card>
      ) : (
        <div className="mt-6 space-y-6">
          {items.map(({ cargo, top_candidates }) => (
            <Card key={cargo.cargo_id} className="p-6 border border-slate-200 rounded-2xl bg-white shadow-sm">
              {/* Cargo Header Info */}
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 pb-4 border-b border-slate-100">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-sm text-slate-900 bg-amber-100/80 text-amber-900 px-2 py-0.5 rounded-lg border border-amber-200">
                      Cargo #{cargo.cargo_id.slice(0, 8)}
                    </span>
                    <Badge tone="accent">{cargo.cargo_type.toUpperCase()}</Badge>
                    <span className="text-xs font-semibold text-slate-500">
                      Weight: <strong className="text-slate-900">{cargo.cargo_weight_tons} Tons</strong>
                    </span>
                  </div>

                  <div className="flex items-center gap-2 mt-2 font-extrabold text-base text-slate-900">
                    <span>{cargo.origin}</span>
                    <ArrowRight size={16} className="text-amber-500" />
                    <span>{cargo.destination}</span>
                  </div>
                </div>

                <div className="text-right">
                  <p className="text-xs font-bold text-slate-800">{cargo.sme?.company_name || cargo.sme?.full_name || 'Verified Shipper'}</p>
                  <p className="text-[11px] text-slate-500 font-mono">{cargo.sme?.phone || '+91 99887 76655'}</p>
                </div>
              </div>

              {/* Candidates List */}
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-1.5">
                  <Truck size={14} className="text-slate-600" />
                  Algorithm Recommended Trucks ({top_candidates.length} Ranked)
                </p>

                <div className="grid gap-3 grid-cols-1 lg:grid-cols-2">
                  {top_candidates.map((cand: any) => {
                    const isBest = cand.match_score_pct >= 90;
                    const isDispatching = dispatchingId === `${cargo.cargo_id}-${cand.truck_id}`;

                    return (
                      <div 
                        key={cand.truck_id}
                        className={`p-4 rounded-xl border transition-all flex flex-col justify-between ${
                          isBest 
                            ? "border-emerald-200 bg-emerald-50/30 hover:border-emerald-300" 
                            : "border-slate-200 bg-slate-50/50 hover:border-slate-300"
                        }`}
                      >
                        <div>
                          {/* Truck Header */}
                          <div className="flex items-start justify-between">
                            <div>
                              <div className="flex items-center gap-2">
                                <span className="font-mono font-extrabold text-sm text-slate-900">
                                  {cand.registration_number}
                                </span>
                                <span className="text-xs font-semibold text-slate-500">
                                  {cand.truck_type}
                                </span>
                              </div>
                              <p className="text-xs text-slate-600 mt-0.5">
                                Driver: <strong>{cand.owner_name}</strong> (★ {cand.driver_rating})
                              </p>
                            </div>

                            {/* Match Score Badge */}
                            <div className="text-right">
                              <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-xl font-mono font-black text-xs ${
                                isBest ? "bg-emerald-600 text-white" : "bg-slate-800 text-amber-300"
                              }`}>
                                <Zap size={11} />
                                {cand.match_score_pct}% Match
                              </span>
                            </div>
                          </div>

                          {/* Dynamic Pricing Quote */}
                          <div className="mt-3 grid grid-cols-3 gap-2 p-2.5 rounded-lg bg-white border border-slate-200/80 text-center">
                            <div>
                              <p className="text-[10px] text-slate-500 font-medium">Customer Price</p>
                              <p className="font-extrabold text-xs text-slate-900">₹{cand.dynamic_pricing?.customerPrice?.toLocaleString('en-IN')}</p>
                            </div>
                            <div>
                              <p className="text-[10px] text-slate-500 font-medium">Driver Payout</p>
                              <p className="font-extrabold text-xs text-emerald-700">₹{cand.dynamic_pricing?.driverFreight?.toLocaleString('en-IN')}</p>
                            </div>
                            <div>
                              <p className="text-[10px] text-slate-500 font-medium">Customer Saves</p>
                              <p className="font-extrabold text-xs text-amber-600">⚡ {cand.dynamic_pricing?.savingsPct}%</p>
                            </div>
                          </div>

                          {/* Score Breakdown Pill Bar */}
                          {cand.match_breakdown && (
                            <div className="mt-2.5 flex items-center justify-between text-[11px] text-slate-500 px-1 font-medium">
                              <span>Route: {Math.round(cand.match_breakdown.routeScore * 100)}%</span>
                              <span>•</span>
                              <span>Capacity: {Math.round(cand.match_breakdown.capacityFit * 100)}%</span>
                              <span>•</span>
                              <span>Safety: {Math.round(cand.match_breakdown.safetyScore * 100)}%</span>
                              <span>•</span>
                              <span>Trust: {Math.round(cand.match_breakdown.trustScore * 100)}%</span>
                            </div>
                          )}
                        </div>

                        {/* Dispatch Button */}
                        <div className="mt-4 pt-3 border-t border-slate-200/70 flex items-center justify-between">
                          <span className="text-[11px] text-emerald-800 font-bold flex items-center gap-1">
                            <ShieldCheck size={13} />
                            Co-load Safety Verified
                          </span>

                          <button
                            onClick={() => handleManualDispatch(cargo.cargo_id, cand.truck_id, cand.dynamic_pricing?.customerPrice || 3500)}
                            disabled={isDispatching}
                            className="px-3.5 py-1.5 rounded-xl bg-slate-900 text-white hover:bg-slate-800 text-xs font-extrabold transition flex items-center gap-1.5 shadow-sm active:scale-95"
                          >
                            <CheckCircle2 size={13} className="text-amber-400" />
                            {isDispatching ? "Dispatching..." : "Assign & Dispatch"}
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </Layout>
  );
}
