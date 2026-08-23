import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { MapPin, Weight } from "lucide-react";
import OwnerLayout from "../components/OwnerLayout";
import { api } from "../lib/api";
import { Badge, Button, Card, CardSkeleton, EmptyState, SearchInput, SectionHead, useToast } from "../components/ui";
import { estimateFromDistance } from "../lib/pricing";

export default function AvailableLoads() {
  const [loads, setLoads] = useState<any[] | null>(null);
  const [trucks, setTrucks] = useState<any[]>([]);
  const [q, setQ] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);
  const toast = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    api.get<any[]>("/cargo").then(setLoads).catch(() => setLoads([]));
    api.get<any[]>("/trucks").then(setTrucks).catch(() => {});
  }, []);

  const accept = async (c: any) => {
    if (!trucks[0]) { toast("Add a truck first to accept loads.", "warn"); return; }
    setBusyId(c.cargo_id);
    try {
      const b = await api.post<{ id: string }>("/bookings", {
        cargo_id: c.cargo_id, truck_id: trucks[0].truck_id,
        agreed_price_inr: estimateFromDistance(c.distance_km, c.cargo_weight_tons),
        owner_initiated: true,
      });
      toast("Load accepted — waiting for shipper confirmation");
      navigate(`/bookings/${b.id}`);
    } catch (e: any) { toast(e.message, "danger"); setBusyId(null); }
  };

  const list = (loads ?? []).filter((c) =>
    !q || `${c.origin} ${c.destination} ${c.cargo_type}`.toLowerCase().includes(q.toLowerCase()));

  return (
    <OwnerLayout>
      <SectionHead title="Available Loads" sub="Open shipper cargo on the network — accept a load that fits your return trip." />
      <Card className="mt-5 p-5">
        <SearchInput value={q} onChange={setQ} placeholder="Search by origin, destination or cargo type…" />
        <div className="mt-4 grid gap-3">
          {loads === null && <CardSkeleton />}
          {loads !== null && list.length === 0 && (
            <EmptyState title="No open loads right now." hint="New shipper requests will appear here." />
          )}
          {list.map((c) => (
            <div key={c.cargo_id} className="rounded-xl border border-line p-4 flex flex-wrap items-center gap-4">
              <div className="flex-1 min-w-[220px]">
                <p className="font-bold text-ink flex items-center gap-2"><MapPin size={15} className="text-accent" /> {c.origin} → {c.destination}</p>
                <p className="mt-1 text-xs text-ink-soft flex items-center gap-3">
                  <span className="inline-flex items-center gap-1"><Weight size={13} /> {c.cargo_weight_tons} T · {c.cargo_type}</span>
                  {c.distance_km && <span>{c.distance_km} km</span>}
                  <span>Pickup {c.pickup_at ? new Date(c.pickup_at).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" }) : "—"}</span>
                </p>
              </div>
              {c.urgency !== "normal" && <Badge tone="warn">{c.urgency}</Badge>}
              <div className="text-right">
                <p className="text-xs text-ink-faint">Estimated earning</p>
                <p className="font-extrabold text-ink tabular-nums">₹{estimateFromDistance(c.distance_km, c.cargo_weight_tons).toLocaleString("en-IN")}</p>
              </div>
              <Button onClick={() => accept(c)} disabled={busyId === c.cargo_id}>
                {busyId === c.cargo_id ? "Accepting…" : "Accept Load"}
              </Button>
            </div>
          ))}
        </div>
      </Card>
    </OwnerLayout>
  );
}
