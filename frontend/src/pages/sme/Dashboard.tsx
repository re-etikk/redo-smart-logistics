import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import { Badge, Button, Card, CardSkeleton, EmptyState, statusLabel, statusTone } from "../../components/ui";
import type { Booking } from "../../lib/types";

export default function SmeDashboard() {
  const { profile } = useAuth();
  const navigate = useNavigate();
  const [bookings, setBookings] = useState<Booking[] | null>(null);
  const [openCargo, setOpenCargo] = useState<any[] | null>(null);

  useEffect(() => {
    api.get<Booking[]>("/bookings").then(setBookings).catch(() => setBookings([]));
    api.get<any[]>("/cargo").then((c) => setOpenCargo(c.filter((x) => x.status === "open"))).catch(() => setOpenCargo([]));
  }, []);

  const active = bookings?.filter((b) => !["completed", "cancelled"].includes(b.status)) ?? [];

  return (
    <Layout>
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-extrabold text-ink">Hello, {profile?.full_name?.split(" ")[0]}</h1>
        <Button onClick={() => navigate("/post-cargo")}>Post new cargo</Button>
      </div>

      <h2 className="mt-8 text-lg font-bold text-ink">Active shipments</h2>
      <div className="mt-3 grid gap-4">
        {bookings === null && <CardSkeleton />}
        {bookings !== null && active.length === 0 && (
          <EmptyState title="No bookings yet." hint="Post cargo and pick from ML-ranked backhaul trucks."
            action={<Button onClick={() => navigate("/post-cargo")}>Find trucks</Button>} />
        )}
        {active.map((b) => (
          <Card key={b.id} hover className="p-5" onClick={() => navigate(`/bookings/${b.id}`)} role="button" tabIndex={0}>
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="font-bold text-ink">{b.cargo.origin} → {b.cargo.destination}</p>
                <p className="text-sm text-ink-soft mt-0.5">{b.cargo.cargo_type} · {b.cargo.cargo_weight_tons} T · {b.truck.truck_type}</p>
              </div>
              <Badge tone={statusTone(b.status)}>{statusLabel(b.status)}</Badge>
            </div>
            <p className="mt-3 text-sm font-semibold text-accent">View booking →</p>
          </Card>
        ))}
      </div>

      <h2 className="mt-8 text-lg font-bold text-ink">Open cargo requests</h2>
      <div className="mt-3 grid gap-4">
        {openCargo === null && <CardSkeleton />}
        {openCargo?.length === 0 && <p className="text-sm text-ink-faint">Nothing open right now.</p>}
        {openCargo?.map((c) => (
          <Card key={c.cargo_id} className="p-5 flex items-center justify-between gap-4">
            <div>
              <p className="font-bold text-ink">{c.origin} → {c.destination}</p>
              <p className="text-sm text-ink-soft">{c.cargo_type} · {c.cargo_weight_tons} T</p>
            </div>
            <Link to={`/find-trucks/${c.cargo_id}`} className="text-sm font-semibold text-accent">See matched trucks →</Link>
          </Card>
        ))}
      </div>
    </Layout>
  );
}
