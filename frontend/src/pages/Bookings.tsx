import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { CheckCircle2, Clock, Package, Truck, XCircle } from "lucide-react";
import Layout from "../components/Layout";
import { api } from "../services/api";
import { useAuth } from "../hooks/useAuth";
import {
  Badge, Button, Card, CardSkeleton, EmptyState, SearchInput, SectionHead,
  StatCard, Tabs, statusLabel, statusTone,
} from "../components/ui";
import type { Booking } from "../lib/types";
import { useRealtimeRefresh } from "../lib/realtime";

const GROUPS: Record<string, string[]> = {
  all: [],
  pending: ["pending", "accepted", "confirmed"],
  transit: ["pickup_ready", "picked_up", "in_transit"],
  delivered: ["delivered", "completed"],
  cancelled: ["cancelled", "disputed"],
};

export default function Bookings() {
  const [bookings, setBookings] = useState<Booking[] | null>(null);
  const [tab, setTab] = useState("all");
  const [q, setQ] = useState("");
  const { profile } = useAuth();
  const navigate = useNavigate();
  const isSme = profile?.role === "sme";

  useEffect(() => { api.get<Booking[]>("/bookings").then(setBookings).catch(() => setBookings([])); }, []);
  useRealtimeRefresh(["bookings"], () =>
    api.get<Booking[]>("/bookings").then(setBookings).catch(() => {}));

  const b = bookings ?? [];
  const filtered = useMemo(() => b.filter((x) =>
    (tab === "all" || GROUPS[tab].includes(x.status)) &&
    (!q || `${x.cargo_id} ${x.cargo.origin} ${x.cargo.destination}`.toLowerCase().includes(q.toLowerCase()))
  ), [b, tab, q]);

  const count = (k: string) => (k === "all" ? b.length : b.filter((x) => GROUPS[k].includes(x.status)).length);

  return (
    <Layout>
      <SectionHead title={isSme ? "My Shipments" : "My Bookings"}
        sub={isSme ? "Track and manage all your shipments in one place." : "Track and manage all your truck bookings in one place."}
        action={isSme ? <Button onClick={() => navigate("/book")}>+ Book New Shipment</Button> : undefined} />

      <div className="mt-5 grid gap-4 grid-cols-2 xl:grid-cols-5">
        <StatCard icon={Package} label={isSme ? "Total Shipments" : "Total Bookings"} value={b.length} tone="info" />
        <StatCard icon={Truck} label="In Transit" value={count("transit")} tone="accent" />
        <StatCard icon={CheckCircle2} label="Delivered" value={count("delivered")} tone="ok" />
        <StatCard icon={Clock} label="Pending" value={count("pending")} tone="warn" />
        <StatCard icon={XCircle} label="Cancelled" value={count("cancelled")} tone="danger" />
      </div>

      <Card className="mt-5 p-5">
        <div className="flex flex-wrap gap-3 items-center">
          <SearchInput value={q} onChange={setQ} placeholder="Search by Shipment ID or Route…" />
        </div>
        <div className="mt-4">
          <Tabs active={tab} onChange={setTab} tabs={[
            { key: "all", label: "All", count: count("all") },
            { key: "transit", label: "In Transit", count: count("transit") },
            { key: "delivered", label: "Delivered", count: count("delivered") },
            { key: "pending", label: "Pending", count: count("pending") },
            { key: "cancelled", label: "Cancelled", count: count("cancelled") },
          ]} />
        </div>

        {bookings === null ? <div className="mt-4"><CardSkeleton /></div> : filtered.length === 0 ? (
          <div className="mt-4"><EmptyState title={isSme ? "No shipments found." : "No bookings found."}
            hint={isSme ? "Book your first shipment to see it here." : "Accept loads to see bookings here."}
            action={isSme ? <Button onClick={() => navigate("/book")}>Book New Shipment</Button>
              : <Button onClick={() => navigate("/loads")}>Find Loads</Button>} /></div>
        ) : (
          <div className="mt-2 overflow-x-auto">
            <table className="w-full text-sm min-w-[720px]">
              <thead><tr className="text-left text-xs font-semibold text-ink-faint border-b border-line">
                <th className="py-2.5 pr-3">Shipment ID</th><th className="py-2.5 pr-3">Route</th>
                <th className="py-2.5 pr-3">Cargo</th><th className="py-2.5 pr-3">Status</th>
                <th className="py-2.5 pr-3">Booked On</th><th className="py-2.5 pr-3">Payment</th><th className="py-2.5">Actions</th>
              </tr></thead>
              <tbody>
                {filtered.map((x) => (
                  <tr key={x.id} className="border-b border-line last:border-0 hover:bg-canvas/60">
                    <td className="py-3.5 pr-3 font-bold text-accent">{x.cargo_id}</td>
                    <td className="py-3.5 pr-3 font-semibold">{x.cargo.origin} → {x.cargo.destination}
                      <span className="block text-xs font-normal text-ink-faint">{x.cargo.distance_km ? `${x.cargo.distance_km} km` : ""}</span></td>
                    <td className="py-3.5 pr-3 text-ink-soft">{x.cargo.cargo_type} · {x.cargo.cargo_weight_tons} T</td>
                    <td className="py-3.5 pr-3"><Badge tone={statusTone(x.status)}>{statusLabel(x.status)}</Badge></td>
                    <td className="py-3.5 pr-3 text-ink-soft">{new Date(x.created_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })}</td>
                    <td className="py-3.5 pr-3 font-semibold">₹{Number(x.agreed_price_inr || 0).toLocaleString("en-IN")}</td>
                    <td className="py-3.5">
                      <div className="flex gap-2">
                        <Button variant="secondary" className="!px-3 !py-1.5 text-xs" onClick={() => navigate(`/bookings/${x.id}`)}>View</Button>
                        {GROUPS.transit.includes(x.status) && (
                          <Button variant="secondary" className="!px-3 !py-1.5 text-xs" onClick={() => navigate(`/tracking/${x.id}`)}>Track</Button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </Layout>
  );
}
