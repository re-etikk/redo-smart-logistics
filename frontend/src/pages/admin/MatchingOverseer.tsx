import { useEffect, useState } from "react";
import { 
  CheckCircle2, AlertTriangle, ShieldCheck, ArrowRight, 
  Zap, RefreshCw, Box, Truck, Sliders, Save, Check, MapPin, Compass
} from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, SectionHead, useToast } from "../../components/ui";

interface MatchingConfig {
  max_pickup_radius_km: number;
  max_detour_km: number;
  min_match_score: number;
  instant_offer_ttl_seconds: number;
}

export default function MatchingOverseer() {
  const [loading, setLoading] = useState(true);
  const [items, setItems] = useState<any[]>([]);
  const [dispatchingId, setDispatchingId] = useState<string | null>(null);
  const [showConfig, setShowConfig] = useState(false);
  const [savingConfig, setSavingConfig] = useState(false);
  const [config, setConfig] = useState<MatchingConfig>({
    max_pickup_radius_km: 10,
    max_detour_km: 35,
    min_match_score: 0.60,
    instant_offer_ttl_seconds: 45,
  });
  const toast = useToast();

  const loadData = () => {
    setLoading(true);
    api.get<any[]>("/admin/matching/candidates")
      .then(res => setItems(res || []))
      .catch(() => setItems([]))
      .finally(() => setLoading(false));

    api.get<MatchingConfig>("/admin/config/matching")
      .then(res => {
        if (res) setConfig(res);
      })
      .catch(() => {});
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleSaveConfig = async () => {
    setSavingConfig(true);
    try {
      await api.put("/admin/config/matching", config);
      toast("Matching engine parameters updated successfully.", "ok");
    } catch (e: any) {
      toast(e?.message || "Failed to update matching parameters.", "danger");
    } finally {
      setSavingConfig(false);
    }
  };

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
          sub="Inspect algorithmic multi-segment candidate scoring, review co-load safety, configure dispatch thresholds, and execute manual dispatch overrides." 
        />
        <div className="flex items-center gap-2 self-start md:self-auto">
          <Button 
            variant="secondary" 
            onClick={() => setShowConfig(!showConfig)}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <Sliders size={14} className={showConfig ? "text-amber-400" : ""} />
            <span>Algorithm Thresholds</span>
          </Button>
          <Button variant="secondary" onClick={loadData} disabled={loading} className="gap-2">
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Matches</span>
          </Button>
        </div>
      </div>

      {/* Matching Parameters Configuration Drawer / Card */}
      {showConfig && (
        <Card className="mt-5 p-5 bg-slate-900/90 border-slate-800 rounded-2xl shadow-xl">
          <div className="flex items-center justify-between pb-3 border-b border-slate-800">
            <div className="flex items-center gap-2">
              <Sliders size={16} className="text-amber-400" />
              <h3 className="font-bold text-white text-sm">Matching Engine Thresholds & Parameters</h3>
            </div>
            <Button
              onClick={handleSaveConfig}
              disabled={savingConfig}
              className="bg-amber-400 hover:bg-amber-500 text-slate-950 font-bold text-xs py-1.5 px-3 rounded-xl flex items-center gap-1.5"
            >
              <Save size={13} />
              <span>{savingConfig ? "Saving..." : "Apply Thresholds"}</span>
            </Button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-4 gap-4 mt-4 text-xs font-semibold">
            <div>
              <label className="block text-slate-400 mb-1">Max Pickup Radius (Km)</label>
              <div className="relative">
                <input
                  type="number"
                  step="1"
                  value={config.max_pickup_radius_km}
                  onChange={(e) => setConfig({ ...config, max_pickup_radius_km: parseFloat(e.target.value) || 10 })}
                  className="w-full px-3 py-1.5 rounded-xl bg-slate-950 border border-slate-700 text-white font-mono font-bold"
                />
              </div>
              <span className="text-[10px] text-slate-500 mt-1 block">Default: 10 Km from driver GPS</span>
            </div>

            <div>
              <label className="block text-slate-400 mb-1">Max Allowed Detour (Km)</label>
              <div className="relative">
                <input
                  type="number"
                  step="1"
                  value={config.max_detour_km}
                  onChange={(e) => setConfig({ ...config, max_detour_km: parseFloat(e.target.value) || 35 })}
                  className="w-full px-3 py-1.5 rounded-xl bg-slate-950 border border-slate-700 text-white font-mono font-bold"
                />
              </div>
              <span className="text-[10px] text-slate-500 mt-1 block">Default: 35 Km off highway corridor</span>
            </div>

            <div>
              <label className="block text-slate-400 mb-1">Min Match Score (%)</label>
              <div className="relative">
                <input
                  type="number"
                  step="0.05"
                  min="0.4"
                  max="0.95"
                  value={config.min_match_score}
                  onChange={(e) => setConfig({ ...config, min_match_score: parseFloat(e.target.value) || 0.6 })}
                  className="w-full px-3 py-1.5 rounded-xl bg-slate-950 border border-slate-700 text-white font-mono font-bold"
                />
              </div>
              <span className="text-[10px] text-slate-500 mt-1 block">Score cutoff for push dispatch</span>
            </div>

            <div>
              <label className="block text-slate-400 mb-1">Instant Offer Countdown (Sec)</label>
              <div className="relative">
                <input
                  type="number"
                  step="5"
                  value={config.instant_offer_ttl_seconds}
                  onChange={(e) => setConfig({ ...config, instant_offer_ttl_seconds: parseInt(e.target.value) || 45 })}
                  className="w-full px-3 py-1.5 rounded-xl bg-slate-950 border border-slate-700 text-white font-mono font-bold"
                />
              </div>
              <span className="text-[10px] text-slate-500 mt-1 block">TTL before next ranked driver</span>
            </div>
          </div>
        </Card>
      )}

      {loading ? (
        <div className="mt-6 space-y-4">
          <CardSkeleton /><CardSkeleton />
        </div>
      ) : items.length === 0 ? (
        <Card className="mt-6 p-10 text-center bg-slate-900/90 border-slate-800 rounded-2xl">
          <Box size={40} className="mx-auto text-slate-600 mb-2" />
          <p className="font-bold text-slate-200">All cargo requests currently dispatched!</p>
          <p className="text-xs text-slate-500 mt-1">New unassigned cargo requests will automatically evaluate candidate trucks and appear here.</p>
        </Card>
      ) : (
        <div className="mt-6 space-y-6">
          {items.map(({ cargo, top_candidates }) => (
            <Card key={cargo.cargo_id} className="p-6 border border-slate-800 rounded-2xl bg-slate-900/90 shadow-xl">
              {/* Cargo Header Info */}
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 pb-4 border-b border-slate-800">
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-bold text-xs text-amber-300 bg-amber-500/10 px-2 py-0.5 rounded-lg border border-amber-500/20 font-mono">
                      Cargo #{cargo.cargo_id.slice(0, 8)}
                    </span>
                    <Badge tone="accent">{cargo.cargo_type.toUpperCase()}</Badge>
                    <span className="text-xs font-semibold text-slate-400">
                      Weight: <strong className="text-white">{cargo.cargo_weight_tons} Tons</strong>
                    </span>
                    {cargo.urgency && (
                      <span className="text-[10px] uppercase font-bold text-amber-400 bg-amber-400/10 px-1.5 py-0.5 rounded">
                        {cargo.urgency}
                      </span>
                    )}
                  </div>

                  <div className="flex items-center gap-2 mt-2 font-black text-base text-white">
                    <span>{cargo.origin}</span>
                    <ArrowRight size={16} className="text-amber-400 shrink-0" />
                    <span>{cargo.destination}</span>
                  </div>
                </div>

                <div className="text-left md:text-right">
                  <p className="text-xs font-bold text-slate-200">{cargo.sme?.company_name || cargo.sme?.full_name || 'Verified Shipper'}</p>
                  <p className="text-[11px] text-slate-500 font-mono">{cargo.sme?.phone || '+91 99887 76655'}</p>
                </div>
              </div>

              {/* Candidates List */}
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3 flex items-center gap-1.5">
                  <Truck size={14} className="text-amber-400" />
                  Algorithm Evaluated Trucks ({top_candidates.length} Candidate Matches)
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
                            ? "border-emerald-500/30 bg-emerald-950/20 hover:border-emerald-500/50" 
                            : "border-slate-800 bg-slate-950/60 hover:border-slate-700"
                        }`}
                      >
                        <div>
                          {/* Truck Header */}
                          <div className="flex items-start justify-between">
                            <div>
                              <div className="flex items-center gap-2">
                                <span className="font-mono font-black text-sm text-white">
                                  {cand.registration_number}
                                </span>
                                <span className="text-xs font-semibold text-slate-400">
                                  {cand.truck_type}
                                </span>
                              </div>
                              <p className="text-xs text-slate-300 mt-0.5">
                                Driver: <strong>{cand.owner_name}</strong> (★ {cand.driver_rating})
                              </p>
                              <p className="text-[11px] text-slate-500 mt-0.5">
                                Available: <strong className="text-slate-300 font-mono">{cand.available_capacity_tons}T</strong> Capacity
                              </p>
                            </div>

                            {/* Match Score Badge */}
                            <div className="text-right">
                              <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-xl font-mono font-black text-xs ${
                                isBest ? "bg-emerald-500 text-slate-950" : "bg-slate-800 text-amber-400"
                              }`}>
                                <Zap size={11} />
                                {cand.match_score_pct}% Match
                              </span>
                            </div>
                          </div>

                          {/* Dynamic Pricing Quote */}
                          <div className="mt-3 grid grid-cols-3 gap-2 p-2.5 rounded-lg bg-slate-900 border border-slate-800 text-center">
                            <div>
                              <p className="text-[10px] text-slate-500 font-medium">Customer Price</p>
                              <p className="font-black text-xs text-white font-mono">₹{cand.dynamic_pricing?.customerPrice?.toLocaleString('en-IN')}</p>
                            </div>
                            <div>
                              <p className="text-[10px] text-slate-500 font-medium">Driver Freight</p>
                              <p className="font-black text-xs text-emerald-400 font-mono">₹{cand.dynamic_pricing?.driverFreight?.toLocaleString('en-IN')}</p>
                            </div>
                            <div>
                              <p className="text-[10px] text-slate-500 font-medium">Shipper Saves</p>
                              <p className="font-black text-xs text-amber-400 font-mono">⚡ {cand.dynamic_pricing?.savingsPct}%</p>
                            </div>
                          </div>

                          {/* Score Breakdown Pill Bar */}
                          {cand.match_breakdown && (
                            <div className="mt-2.5 flex items-center justify-between text-[11px] text-slate-400 px-1 font-medium flex-wrap gap-1">
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
                        <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between">
                          <span className="text-[11px] text-emerald-400 font-bold flex items-center gap-1">
                            <ShieldCheck size={13} />
                            Co-load Safety Verified
                          </span>

                          <button
                            onClick={() => handleManualDispatch(cargo.cargo_id, cand.truck_id, cand.dynamic_pricing?.customerPrice || 3500)}
                            disabled={isDispatching}
                            className="px-3.5 py-1.5 rounded-xl bg-amber-400 text-slate-950 hover:bg-amber-300 text-xs font-black transition flex items-center gap-1.5 shadow-sm active:scale-95"
                          >
                            <CheckCircle2 size={13} className="text-slate-950" />
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
