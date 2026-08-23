import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Route as RouteIcon } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, EmptyState, SectionHead, Tabs, statusLabel, statusTone } from "../../components/ui";
import type { Booking } from "../../lib/types";

const ONGOING = ["confirmed", "pickup_ready", "picked_up", "in_transit"];

export default function Trips() {
  const [bookings, setBookings] = useState<Booking[] | null>(null);
  const [tab, setTab] = useState("ongoing");
  const navigate = useNavigate();
  useEffect(() => { api.get<Booking[]>("/bookings").then(setBookings).catch(() => setBookings([])); }, []);

  const trips = (bookings ?? []).filter((b) => !["pending", "accepted"].includes(b.status));
  const list = trips.filter((b) =>
    tab === "ongoing" ? ONGOING.includes(b.status)
    : tab === "completed" ? ["delivered", "completed"].includes(b.status)
    : ["cancelled", "disputed"].includes(b.status));

  return (
    <Layout>
      <SectionHead title="Trips" sub="Monitor and manage all your ongoing and completed trips." />
      <Card className="mt-5 p-5">
        <Tabs active={tab} onChange={setTab} tabs={[
          { key: "ongoing", label: "Ongoing", count: trips.filter((b) => ONGOING.includes(b.status)).length },
          { key: "completed", label: "Completed", count: trips.filter((b) => ["delivered", "completed"].includes(b.status)).length },
          { key: "cancelled", label: "Cancelled", count: trips.filter((b) => ["cancelled", "disputed"].includes(b.status)).length },
        ]} />
        <div className="mt-4 grid gap-3">
          {bookings === null && <CardSkeleton />}
          {bookings !== null && list.length === 0 && (
            <EmptyState title="No trips here." hint="Confirmed bookings become trips automatically." />
          )}
          {list.map((b) => (
            <div key={b.id} className="rounded-xl border border-line p-4 flex flex-wrap items-center gap-4">
              <span className="h-11 w-11 rounded-xl bg-brand-soft text-brand-dark grid place-items-center"><RouteIcon size={20} /></span>
              <div className="flex-1 min-w-[200px]">
                <p className="font-bold text-ink text-sm">{b.cargo.origin} → {b.cargo.destination}</p>
                <p className="text-xs text-ink-soft">{b.truck.truck_type} · {b.truck.registration_number} · {b.cargo.cargo_weight_tons} T{b.cargo.distance_km ? ` · ${b.cargo.distance_km} km` : ""}</p>
              </div>
              <div className="text-right">
                <p className="text-xs text-ink-faint">Trip Earning</p>
                <p className="font-extrabold tabular-nums">₹{Number(b.agreed_price_inr || 0).toLocaleString("en-IN")}</p>
              </div>
              <Badge tone={statusTone(b.status)}>{statusLabel(b.status)}</Badge>
              <Button variant="secondary" className="!px-3 !py-1.5 text-xs" onClick={() => navigate(`/bookings/${b.id}`)}>View Details</Button>
            </div>
          ))}
        </div>
      </Card>
    </Layout>
  );
}
