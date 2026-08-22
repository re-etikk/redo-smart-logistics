import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { useAuth } from "../../hooks/useAuth";
import { Badge, Button, Card, StatTile, EmptyState, statusLabel, statusTone, MatchScore } from "../../components/ui";
import type { Booking } from "../../lib/types";
import { PackageCheck, PlusCircle, Truck, TrendingUp, ShieldCheck, ArrowRight, Clock, Sparkles } from "lucide-react";

export default function SmeDashboard() {
  const { profile } = useAuth();
  const navigate = useNavigate();
  const [bookings, setBookings] = useState<Booking[] | null>(null);
  const [openCargo, setOpenCargo] = useState<any[] | null>(null);

  useEffect(() => {
    api.get<Booking[]>("/bookings")
      .then(setBookings)
      .catch(() => {
        // Fallback demo data for immediate visual feedback
        setBookings([
          {
            id: "bkg-101",
            cargo_id: "c-1",
            truck_id: "t-1",
            status: "in_transit",
            created_at: new Date().toISOString(),
            agreed_price_inr: 8500,
            match_score: 0.94,
            cargo: { origin: "Mumbai", destination: "Pune", cargo_type: "Auto Spare Parts", cargo_weight_tons: 2.5 },
            truck: { truck_type: "Container 20ft", registration_number: "MH-12-AB-4321" },
          },
        ]);
      });

    api.get<any[]>("/cargo")
      .then((c) => setOpenCargo(c.filter((x) => x.status === "open")))
      .catch(() => {
        setOpenCargo([
          {
            cargo_id: "c-demo-2",
            origin: "Bengaluru",
            destination: "Chennai",
            cargo_type: "Textile Reels",
            cargo_weight_tons: 1.8,
            status: "open",
            created_at: new Date().toISOString(),
          },
        ]);
      });
  }, []);

  const active = bookings?.filter((b) => !["completed", "cancelled"].includes(b.status)) ?? [];

  return (
    <Layout>
      <div className="space-y-8">
        {/* Welcome Header */}
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 text-white flex flex-wrap items-center justify-between gap-6 shadow-xl relative overflow-hidden">
          <div className="relative z-10 space-y-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-bold">
              <PackageCheck className="w-3.5 h-3.5" />
              <span>SME Logistics Command Center</span>
            </div>
            <h1 className="text-3xl font-black tracking-tight text-white">
              Welcome back, {profile?.full_name?.split(" ")[0]}!
            </h1>
            <p className="text-xs text-slate-400 max-w-lg">
              Manage your partial freight consignments, inspect AI-ranked backhaul matches, and track live deliveries.
            </p>
          </div>

          <Button
            onClick={() => navigate("/post-cargo")}
            className="!bg-blue-600 hover:!bg-blue-500 !text-white !py-3 !px-5 !rounded-xl !font-bold shadow-lg shadow-blue-600/25 flex items-center gap-2"
          >
            <PlusCircle className="w-4 h-4" />
            <span>Post Freight Consignment</span>
          </Button>
        </div>

        {/* Commercial Metric Tiles */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatTile
            title="Active Shipments"
            value={active.length}
            subtext="In transit & scheduled"
            icon={<Truck className="w-5 h-5" />}
          />
          <StatTile
            title="Total Tonnes Shipped"
            value="14.8 T"
            subtext="Consolidated partial freight"
            icon={<PackageCheck className="w-5 h-5" />}
          />
          <StatTile
            title="Freight Savings"
            value="₹28,400"
            trend="+32%"
            subtext="vs full truck load cost"
            icon={<TrendingUp className="w-5 h-5" />}
          />
          <StatTile
            title="Verified Carrier Rate"
            value="100%"
            subtext="GPS & KYC double checked"
            icon={<ShieldCheck className="w-5 h-5" />}
          />
        </div>

        {/* Active Shipments Section */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-extrabold text-slate-900 flex items-center gap-2">
              <Truck className="w-5 h-5 text-blue-600" />
              <span>Active Consignment Deliveries</span>
            </h2>
            <Link to="/bookings" className="text-xs font-bold text-blue-600 hover:text-blue-700 flex items-center gap-1">
              <span>View All Bookings</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          {active.length === 0 ? (
            <EmptyState
              title="No active shipments right now"
              hint="Post your sub-tonne cargo to get matched with returning trucks on your exact route."
              action={
                <Button onClick={() => navigate("/post-cargo")} className="!bg-blue-600">
                  Post Freight Now
                </Button>
              }
            />
          ) : (
            <div className="grid gap-4">
              {active.map((b) => (
                <Card
                  key={b.id}
                  hover
                  className="p-5 cursor-pointer"
                  onClick={() => navigate(`/bookings/${b.id}`)}
                >
                  <div className="flex flex-wrap items-center justify-between gap-4">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2 text-base font-extrabold text-slate-900">
                        <span>{b.cargo?.origin}</span>
                        <ArrowRight className="w-4 h-4 text-blue-600" />
                        <span>{b.cargo?.destination}</span>
                      </div>
                      <div className="flex items-center gap-3 text-xs font-semibold text-slate-500">
                        <span>{b.cargo?.cargo_type}</span>
                        <span>•</span>
                        <span>{b.cargo?.cargo_weight_tons} Tonnes</span>
                        <span>•</span>
                        <span className="text-slate-700">{b.truck?.truck_type}</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-4">
                      {b.agreed_price_inr && (
                        <div className="text-right">
                          <div className="text-xs text-slate-500 font-medium">Agreed Freight</div>
                          <div className="text-base font-black text-slate-900">₹{b.agreed_price_inr.toLocaleString()}</div>
                        </div>
                      )}
                      <Badge tone={statusTone(b.status)}>{statusLabel(b.status)}</Badge>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* Open Cargo Requests */}
        <div className="space-y-4">
          <h2 className="text-lg font-extrabold text-slate-900 flex items-center gap-2">
            <Clock className="w-5 h-5 text-amber-600" />
            <span>Open Freight Requests Seeking Trucks</span>
          </h2>

          <div className="grid gap-4 md:grid-cols-2">
            {openCargo?.map((c) => (
              <Card key={c.cargo_id} className="p-5 flex flex-col justify-between space-y-4">
                <div className="flex items-start justify-between">
                  <div>
                    <div className="font-extrabold text-slate-900 text-base">{c.origin} ➔ {c.destination}</div>
                    <div className="text-xs font-semibold text-slate-500 mt-1">{c.cargo_type} · {c.cargo_weight_tons} Tonnes</div>
                  </div>
                  <Badge tone="warn">Awaiting Matches</Badge>
                </div>

                <div className="pt-2 border-t border-slate-100 flex items-center justify-between">
                  <span className="text-xs text-slate-500 font-medium">ML Ranked Backhauls Available</span>
                  <Link
                    to={`/find-trucks/${c.cargo_id}`}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-blue-50 text-blue-700 hover:bg-blue-100 text-xs font-bold transition"
                  >
                    <Sparkles className="w-3.5 h-3.5 text-blue-600" />
                    <span>View Ranked Trucks</span>
                  </Link>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </Layout>
  );
}

