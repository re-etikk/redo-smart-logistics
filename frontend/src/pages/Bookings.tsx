import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../components/Layout";
import { api } from "../services/api";
import { useAuth } from "../hooks/useAuth";
import { Badge, Card, CardSkeleton, EmptyState, statusLabel, statusTone } from "../components/ui";
import type { Booking } from "../lib/types";

export default function Bookings() {
  const [bookings, setBookings] = useState<Booking[] | null>(null);
  const { profile } = useAuth();
  const navigate = useNavigate();
  useEffect(() => { api.get<Booking[]>("/bookings").then(setBookings).catch(() => setBookings([])); }, []);

  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Bookings</h1>
      <div className="mt-6 grid gap-4">
        {bookings === null && <><CardSkeleton /><CardSkeleton /></>}
        {bookings?.length === 0 && (
          <EmptyState title="No bookings yet."
            hint={profile?.role === "sme" ? "Post cargo to request your first booking." : "Incoming requests from shippers will appear here."} />
        )}
        {bookings?.map((b) => (
          <Card key={b.id} hover className="p-5" role="button" tabIndex={0} onClick={() => navigate(`/bookings/${b.id}`)}>
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="font-bold text-ink">{b.cargo.origin} → {b.cargo.destination}</p>
                <p className="text-sm text-ink-soft mt-0.5">
                  {b.cargo.cargo_type} · {b.cargo.cargo_weight_tons} T · {b.truck.truck_type} {b.truck.registration_number}
                  {b.agreed_price_inr ? ` · ₹${Number(b.agreed_price_inr).toLocaleString("en-IN")}` : ""}
                </p>
              </div>
              <Badge tone={statusTone(b.status)}>{statusLabel(b.status)}</Badge>
            </div>
          </Card>
        ))}
      </div>
    </Layout>
  );
}
