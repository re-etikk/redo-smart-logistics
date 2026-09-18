import { useEffect, useState } from "react";
import { IndianRupee, Save, Sliders, Calculator, Sparkles, Check } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Button, Card, CardSkeleton, SectionHead, useToast } from "../../components/ui";

export default function PricingControl() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [configs, setConfigs] = useState<any[]>([]);
  const [selectedCorridor, setSelectedCorridor] = useState<string>("delhi_patna");
  const [form, setForm] = useState<any>({});
  const toast = useToast();

  // Simulation State
  const [simWeight, setSimWeight] = useState<number>(2.5);
  const [simVolume, setSimVolume] = useState<number>(180); // CFT
  const [simDistance, setSimDistance] = useState<number>(490); // Km
  const [simCargoType, setSimCargoType] = useState<string>("fragile");

  const loadData = () => {
    setLoading(true);
    api.get<any[]>("/admin/pricing")
      .then(res => {
        setConfigs(res || []);
        const active = (res || []).find((c: any) => c.corridor_id === selectedCorridor) || res?.[0];
        if (active) {
          setSelectedCorridor(active.corridor_id);
          setForm(active);
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleCorridorChange = (corridorId: string) => {
    setSelectedCorridor(corridorId);
    const item = configs.find(c => c.corridor_id === corridorId);
    if (item) setForm(item);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await api.put(`/admin/pricing/${selectedCorridor}`, form);
      toast(`Rules updated for ${form.corridor_name || selectedCorridor}. Effective immediately.`, "ok");
      loadData();
    } catch (e: any) {
      toast(e?.message || "Could not save pricing configurations.", "danger");
    } finally {
      setSaving(false);
    }
  };

  // Live Simulator Math
  const volWeight = +(simVolume / 120).toFixed(2);
  const billableWeight = Math.max(simWeight, volWeight);
  const baseRate = Number(form.base_rate_per_ton_km) || 2.40;
  const rawBase = billableWeight * simDistance * baseRate;
  const mCargo = simCargoType === 'fragile' ? Number(form.fragile_multiplier || 1.18)
    : simCargoType === 'fmcg' ? Number(form.fmcg_multiplier || 1.08)
    : simCargoType === 'perishable' ? Number(form.perishable_multiplier || 1.25)
    : 1.0;
  const fOccupancy = 0.88; // Fill My Truck discount
  const driverFreight = Math.max(Number(form.min_fare_inr || 1500), Math.round(rawBase * mCargo * fOccupancy));
  const commPct = Number(form.platform_commission_pct || 0.08);
  const redoFee = Math.round(driverFreight * commPct);
  const customerPrice = driverFreight + redoFee;
  const dedicatedPrice = Math.max(4500, Math.round(simDistance * 18 + 1500));
  const savingsPct = Math.max(0, Math.round(((dedicatedPrice - customerPrice) / dedicatedPrice) * 100));

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="Dynamic Pricing & Commission Control" 
          sub="Tune lane rates, cargo safety multipliers, and platform commission in real-time without redeploying code." 
        />
        <Button 
          variant="primary" 
          onClick={handleSave} 
          disabled={saving || loading}
          className="gap-2 bg-amber-500 hover:bg-amber-600 text-slate-950 font-bold self-start md:self-auto"
        >
          {saving ? <Sparkles size={16} className="animate-spin" /> : <Save size={16} />}
          Save Corridor Rates
        </Button>
      </div>

      {loading ? (
        <div className="mt-6"><CardSkeleton /></div>
      ) : (
        <div className="mt-6 grid gap-6 grid-cols-1 lg:grid-cols-3">
          {/* Left Column: Corridor Config Form */}
          <div className="lg:col-span-2 space-y-6">
            {/* Corridor Tabs */}
            <div className="flex flex-wrap gap-2">
              {configs.map(c => (
                <button
                  key={c.corridor_id}
                  onClick={() => handleCorridorChange(c.corridor_id)}
                  className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
                    selectedCorridor === c.corridor_id
                      ? "bg-slate-900 text-amber-400 shadow-md"
                      : "bg-white text-slate-600 border border-line hover:bg-slate-50"
                  }`}
                >
                  {selectedCorridor === c.corridor_id && <Check size={12} />}
                  {c.corridor_name}
                </button>
              ))}
            </div>

            {/* Main Parameters Card */}
            <Card className="p-6 border border-slate-200 rounded-2xl bg-white shadow-sm">
              <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2 mb-4">
                <Sliders size={16} className="text-amber-500" />
                Base Lane Rates & Minimum Fare
              </h3>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Base Rate (₹ / Ton-Km)</label>
                  <div className="relative">
                    <span className="absolute left-3 top-2.5 text-slate-400 text-sm font-bold">₹</span>
                    <input
                      type="number"
                      step="0.05"
                      value={form.base_rate_per_ton_km ?? 2.40}
                      onChange={(e) => setForm({ ...form, base_rate_per_ton_km: parseFloat(e.target.value) })}
                      className="w-full pl-7 pr-3 py-2 rounded-xl border border-slate-300 text-sm font-mono font-bold text-slate-900 focus:ring-2 focus:ring-amber-500"
                    />
                  </div>
                  <p className="text-[10px] text-slate-400 mt-1">Plains highway benchmark: ₹2.20 - ₹2.50</p>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Minimum Booking Fare (₹)</label>
                  <div className="relative">
                    <span className="absolute left-3 top-2.5 text-slate-400 text-sm font-bold">₹</span>
                    <input
                      type="number"
                      step="50"
                      value={form.min_fare_inr ?? 1500}
                      onChange={(e) => setForm({ ...form, min_fare_inr: parseFloat(e.target.value) })}
                      className="w-full pl-7 pr-3 py-2 rounded-xl border border-slate-300 text-sm font-mono font-bold text-slate-900 focus:ring-2 focus:ring-amber-500"
                    />
                  </div>
                  <p className="text-[10px] text-slate-400 mt-1">Guarantees driver base compensation</p>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Detour Fuel Rate (₹ / Km)</label>
                  <div className="relative">
                    <span className="absolute left-3 top-2.5 text-slate-400 text-sm font-bold">₹</span>
                    <input
                      type="number"
                      step="1"
                      value={form.detour_rate_per_km ?? 25.0}
                      onChange={(e) => setForm({ ...form, detour_rate_per_km: parseFloat(e.target.value) })}
                      className="w-full pl-7 pr-3 py-2 rounded-xl border border-slate-300 text-sm font-mono font-bold text-slate-900 focus:ring-2 focus:ring-amber-500"
                    />
                  </div>
                  <p className="text-[10px] text-slate-400 mt-1">100% credited to driver for off-highway leg</p>
                </div>
              </div>

              {/* Commission Slider */}
              <div className="mt-6 pt-5 border-t border-slate-100">
                <div className="flex justify-between items-center mb-2">
                  <label className="text-xs font-bold text-slate-800">
                    ReDo Platform Commission: <span className="text-amber-600 font-mono text-sm">{Math.round((form.platform_commission_pct ?? 0.08) * 100)}%</span>
                  </label>
                  <span className="text-[11px] text-slate-400">Industry standard: 6% - 10%</span>
                </div>
                <input
                  type="range"
                  min="0.04"
                  max="0.15"
                  step="0.01"
                  value={form.platform_commission_pct ?? 0.08}
                  onChange={(e) => setForm({ ...form, platform_commission_pct: parseFloat(e.target.value) })}
                  className="w-full accent-amber-500 h-2 bg-slate-200 rounded-lg cursor-pointer"
                />
              </div>
            </Card>

            {/* Cargo Risk Multipliers Card */}
            <Card className="p-6 border border-slate-200 rounded-2xl bg-white shadow-sm">
              <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2 mb-3">
                <IndianRupee size={16} className="text-emerald-500" />
                Cargo Category Risk Multipliers (M_cargo)
              </h3>
              <p className="text-xs text-slate-500 mb-4">
                Compensates driver for careful driving, cargo lashing, and liability on specialized goods.
              </p>

              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-xs font-bold text-slate-700 block">Fragile / Glass</span>
                  <input
                    type="number"
                    step="0.02"
                    value={form.fragile_multiplier ?? 1.18}
                    onChange={(e) => setForm({ ...form, fragile_multiplier: parseFloat(e.target.value) })}
                    className="mt-1 w-full px-2.5 py-1.5 rounded-lg border border-slate-300 font-mono font-bold text-xs"
                  />
                  <span className="text-[10px] text-slate-400 mt-1 block">Default: +18%</span>
                </div>

                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-xs font-bold text-slate-700 block">FMCG / Food</span>
                  <input
                    type="number"
                    step="0.02"
                    value={form.fmcg_multiplier ?? 1.08}
                    onChange={(e) => setForm({ ...form, fmcg_multiplier: parseFloat(e.target.value) })}
                    className="mt-1 w-full px-2.5 py-1.5 rounded-lg border border-slate-300 font-mono font-bold text-xs"
                  />
                  <span className="text-[10px] text-slate-400 mt-1 block">Default: +8%</span>
                </div>

                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-xs font-bold text-slate-700 block">Perishable Goods</span>
                  <input
                    type="number"
                    step="0.02"
                    value={form.perishable_multiplier ?? 1.25}
                    onChange={(e) => setForm({ ...form, perishable_multiplier: parseFloat(e.target.value) })}
                    className="mt-1 w-full px-2.5 py-1.5 rounded-lg border border-slate-300 font-mono font-bold text-xs"
                  />
                  <span className="text-[10px] text-slate-400 mt-1 block">Default: +25%</span>
                </div>

                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-xs font-bold text-slate-700 block">High-Value Electronics</span>
                  <input
                    type="number"
                    step="0.02"
                    value={form.high_value_multiplier ?? 1.30}
                    onChange={(e) => setForm({ ...form, high_value_multiplier: parseFloat(e.target.value) })}
                    className="mt-1 w-full px-2.5 py-1.5 rounded-lg border border-slate-300 font-mono font-bold text-xs"
                  />
                  <span className="text-[10px] text-slate-400 mt-1 block">Default: +30%</span>
                </div>
              </div>
            </Card>
          </div>

          {/* Right Column: Live Dynamic Pricing Sandbox Simulator */}
          <div>
            <Card className="p-6 border border-amber-300 bg-gradient-to-b from-amber-50/40 to-white rounded-2xl shadow-md sticky top-20">
              <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2 mb-2">
                <Calculator size={17} className="text-amber-600" />
                Live Pricing Sandbox
              </h3>
              <p className="text-xs text-slate-600 mb-4 font-medium">
                Simulate quotes in real-time based on the parameters on the left.
              </p>

              <div className="space-y-3.5 text-xs font-semibold text-slate-700">
                <div>
                  <label className="block mb-1">Actual Weight (Tons)</label>
                  <input
                    type="number"
                    step="0.1"
                    value={simWeight}
                    onChange={(e) => setSimWeight(parseFloat(e.target.value) || 0.1)}
                    className="w-full px-3 py-1.5 rounded-xl border border-slate-300 font-mono font-bold"
                  />
                </div>

                <div>
                  <label className="block mb-1">Cargo Volume (Cubic Feet / CFT)</label>
                  <input
                    type="number"
                    step="10"
                    value={simVolume}
                    onChange={(e) => setSimVolume(parseFloat(e.target.value) || 0)}
                    className="w-full px-3 py-1.5 rounded-xl border border-slate-300 font-mono font-bold"
                  />
                  <span className="text-[10px] text-slate-400 font-medium">Volumetric Weight: {volWeight} Tons (120 CFT = 1T)</span>
                </div>

                <div>
                  <label className="block mb-1">Highway Distance (Km)</label>
                  <input
                    type="number"
                    step="10"
                    value={simDistance}
                    onChange={(e) => setSimDistance(parseFloat(e.target.value) || 10)}
                    className="w-full px-3 py-1.5 rounded-xl border border-slate-300 font-mono font-bold"
                  />
                </div>

                <div>
                  <label className="block mb-1">Cargo Category</label>
                  <select
                    value={simCargoType}
                    onChange={(e) => setSimCargoType(e.target.value)}
                    className="w-full px-3 py-1.5 rounded-xl border border-slate-300 text-xs font-bold"
                  >
                    <option value="general">Standard / General Goods</option>
                    <option value="fragile">Fragile / Glassware</option>
                    <option value="fmcg">FMCG / Packaged Food</option>
                    <option value="perishable">Perishable Goods</option>
                  </select>
                </div>
              </div>

              {/* Real-time Calculation Result Box */}
              <div className="mt-5 p-4 rounded-xl bg-slate-900 text-white space-y-2.5">
                <div className="flex justify-between items-center text-xs text-slate-400">
                  <span>Billable Weight:</span>
                  <span className="font-mono text-white font-bold">{billableWeight} Tons</span>
                </div>
                <div className="flex justify-between items-center text-xs text-slate-400">
                  <span>Driver Freight:</span>
                  <span className="font-mono text-emerald-400 font-bold">₹{driverFreight.toLocaleString('en-IN')}</span>
                </div>
                <div className="flex justify-between items-center text-xs text-slate-400">
                  <span>ReDo Commission ({Math.round(commPct * 100)}%):</span>
                  <span className="font-mono text-amber-400 font-bold">₹{redoFee.toLocaleString('en-IN')}</span>
                </div>
                <div className="pt-2 border-t border-slate-800 flex justify-between items-center">
                  <span className="text-xs font-bold text-white">Customer Price:</span>
                  <span className="font-mono text-lg font-black text-amber-400">₹{customerPrice.toLocaleString('en-IN')}</span>
                </div>
              </div>

              {/* Savings callout */}
              <div className="mt-3 p-2.5 rounded-xl bg-emerald-50 border border-emerald-200 text-center">
                <p className="text-xs font-extrabold text-emerald-800">
                  ⚡ {savingsPct}% Cheaper Than Full Dedicated Truck
                </p>
                <p className="text-[10px] text-emerald-600">
                  Shipper saves ~₹{(dedicatedPrice - customerPrice).toLocaleString('en-IN')} on this shipment!
                </p>
              </div>
            </Card>
          </div>
        </div>
      )}
    </Layout>
  );
}
