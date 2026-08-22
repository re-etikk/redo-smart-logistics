import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Box, CheckCircle2, Download, IndianRupee, MapPin, Package, Truck } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import { Badge, Button, Card, CardSkeleton, EmptyState, StatCard, statusLabel, statusTone } from "../../components/ui";
import type { Booking } from "../../lib/types";

const IN_TRANSIT = ["pickup_ready", "picked_up", "in_transit"];

export default function SmeDashboard() {
  const { profile } = useAuth();
  const navigate = useNavigate();
  const [bookings, setBookings] = useState<Booking[] | null>(null);

  useEffect(() => { api.get<Booking[]>("/bookings").then(setBookings).catch(() => setBookings([])); }, []);

  const b = bookings ?? [];
  const spend = b.filter((x) => x.status === "completed").reduce((a, x) => a + Number(x.agreed_price_inr || 0), 0);

  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Welcome back, {profile?.full_name?.split(" ")[0]}! 👋</h1>
      <div className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard icon={Package} label="Total Shipments" value={b.length} tone="info" />
        <StatCard icon={Truck} label="In Transit" value={b.filter((x) => IN_TRANSIT.includes(x.status)).length} tone="accent" />
        <StatCard icon={CheckCircle2} label="Delivered" value={b.filter((x) => ["delivered", "completed"].includes(x.status)).length} tone="ok" />
        <StatCard icon={IndianRupee} label="Total Spend" value={`₹${spend.toLocaleString("en-IN")}`} tone="purple" />
      </div>

      <div className="mt-6 grid gap-5 xl:grid-cols-[1fr_320px]">
        <Card className="p-5">
          <div className="flex items-center justify-between">
            <h2 className="font-bold text-ink">Recent Shipments</h2>
            <Link to="/shipments" className="text-sm font-semibold text-accent">View All Shipments →</Link>
          </div>
          {bookings === null ? <div className="mt-4"><CardSkeleton /></div> : b.length === 0 ? (
            <div className="mt-4"><EmptyState title="No shipments yet." hint="Book your first shipment to get started."
              action={<Button onClick={() => navigate("/book")}>Book New Shipment</Button>} /></div>
          ) : (
            <div className="mt-3 overflow-x-auto">
              <table className="w-full text-sm min-w-[560px]">
                <thead><tr className="text-left text-xs font-semibold text-ink-faint border-b border-line">
                  <th className="py-2 pr-3">Shipment</th><th className="py-2 pr-3">Route</th>
                  <th className="py-2 pr-3">Status</th><th className="py-2 pr-3">Booked On</th><th className="py-2">Action</th>
                </tr></thead>
                <tbody>
                  {b.slice(0, 5).map((x) => (
                    <tr key={x.id} className="border-b border-line last:border-0">
                      <td className="py-3 pr-3 font-bold text-accent">{x.cargo_id}</td>
                      <td className="py-3 pr-3 font-medium">{x.cargo.origin} → {x.cargo.destination}</td>
                      <td className="py-3 pr-3"><Badge tone={statusTone(x.status)}>{statusLabel(x.status)}</Badge></td>
                      <td className="py-3 pr-3 text-ink-soft">{new Date(x.created_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short" })}</td>
                      <td className="py-3"><Link to={`/bookings/${x.id}`} className="font-semibold text-accent">View</Link></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>

        <div className="space-y-4">
          <Card className="p-5">
            <h2 className="font-bold text-ink">Quick Actions</h2>
            <div className="mt-3 grid grid-cols-2 gap-2">
              {[
                { icon: Box, label: "Book New Shipment", to: "/book" },
                { icon: MapPin, label: "Track Shipment", to: "/shipments" },
                { icon: Download, label: "Download Invoice", to: "/invoices" },
                { icon: IndianRupee, label: "Price Calculator", to: "/rate-card" },
              ].map(({ icon: Icon, label, to }) => (
                <button key={label} onClick={() => navigate(to)}
                  className="rounded-xl border border-line p-3 text-left hover:border-accent transition">
                  <Icon size={18} className="text-accent" />
                  <span className="mt-1.5 block text-xs font-bold text-ink">{label}</span>
                </button>
              ))}
            </div>
          </Card>
          <Card className="p-5 bg-accent-soft border-0">
            <p className="font-bold text-ink">Ship more, save more!</p>
            <p className="mt-1 text-xs text-ink-soft">Post partial loads on active return corridors for the best backhaul rates.</p>
            <Button className="mt-3" onClick={() => navigate("/book")}>Book Now</Button>
          </Card>
        </div>
      </div>
    </Layout>
  );
}
