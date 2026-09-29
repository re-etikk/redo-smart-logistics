import { useEffect, useState, useMemo } from "react";
import { 
  Package, Search, RefreshCw, Truck, MapPin, 
  Calendar, CheckCircle2, Clock, AlertTriangle, ShieldCheck, Phone, ArrowRight,
  ExternalLink, Filter, Layers
} from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { supabase } from "../../lib/supabase";
import { Badge, Button, Card, CardSkeleton, SectionHead, useToast } from "../../components/ui";

interface BookingRecord {
  id: string;
  status: string;
  agreed_price_inr: number;
  match_score?: number;
  pickup_otp_verified_at?: string | null;
  created_at: string;
  cargo?: {
    cargo_id: string;
    origin: string;
    destination: string;
    distance_km?: number;
    cargo_type: string;
    cargo_weight_tons: number;
    pickup_date?: string;
    urgency?: string;
    sme?: {
      id: string;
      full_name: string;
      phone?: string;
      company_name?: string;
    };
  };
  truck?: {
    truck_id: string;
    registration_number: string;
    truck_type: string;
    body_type?: string;
    default_capacity_tons: number;
    owner?: {
      id: string;
      full_name: string;
      phone?: string;
    };
  };
}

export default function AdminBookings() {
  const [loading, setLoading] = useState(true);
  const [bookings, setBookings] = useState<BookingRecord[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedBooking, setSelectedBooking] = useState<BookingRecord | null>(null);
  const [actionBusy, setActionBusy] = useState(false);
  const toast = useToast();

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await api.get<BookingRecord[]>("/admin/bookings");
      setBookings(Array.isArray(res) ? res : []);
    } catch (err) {
      console.error('Error fetching bookings:', err);
      setBookings([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();

    // 3. Realtime auto-update on new bookings or status changes
    const channel = supabase
      .channel('admin-bookings-stream')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'bookings' },
        (payload) => {
          toast(`Booking event: ${payload.eventType} (${(payload.new as any)?.status || 'updated'})`, "ok");
          loadData();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const handleUpdateStatus = async (id: string, newStatus: string) => {
    setActionBusy(true);
    try {
      await api.patch(`/admin/bookings/${id}/status`, { status: newStatus });
      toast(`Booking status updated to ${newStatus}`, "ok");
      loadData();
      setSelectedBooking(null);
    } catch (err: any) {
      toast(err?.message || "Failed to update status", "danger");
    } finally {
      setActionBusy(false);
    }
  };

  // Metrics summary
  const metrics = useMemo(() => {
    const total = bookings.length;
    const inTransit = bookings.filter(b => ['picked_up', 'in_transit'].includes(b.status)).length;
    const pending = bookings.filter(b => ['pending', 'accepted', 'confirmed', 'pickup_ready'].includes(b.status)).length;
    const completed = bookings.filter(b => ['delivered', 'completed'].includes(b.status)).length;
    const totalFreight = bookings.reduce((sum, b) => sum + (Number(b.agreed_price_inr) || 0), 0);
    return { total, inTransit, pending, completed, totalFreight };
  }, [bookings]);

  // Filtered list
  const filteredBookings = useMemo(() => {
    return bookings.filter(b => {
      const matchStatus = statusFilter === "all" || b.status === statusFilter ||
        (statusFilter === "active" && ['accepted', 'confirmed', 'pickup_ready', 'picked_up', 'in_transit'].includes(b.status));

      const q = searchQuery.toLowerCase().trim();
      if (!q) return matchStatus;

      const cargo = b.cargo;
      const truck = b.truck;
      const idMatch = b.id.toLowerCase().includes(q);
      const originMatch = cargo?.origin?.toLowerCase().includes(q);
      const destMatch = cargo?.destination?.toLowerCase().includes(q);
      const truckMatch = truck?.registration_number?.toLowerCase().includes(q);
      const shipperMatch = cargo?.sme?.full_name?.toLowerCase().includes(q) || cargo?.sme?.company_name?.toLowerCase().includes(q);

      return matchStatus && (idMatch || originMatch || destMatch || truckMatch || shipperMatch);
    });
  }, [bookings, statusFilter, searchQuery]);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'in_transit':
        return <Badge tone="info">In Transit</Badge>;
      case 'picked_up':
      case 'pickup_ready':
        return <Badge tone="accent">Pickup Ready</Badge>;
      case 'accepted':
      case 'confirmed':
        return <Badge tone="ok">Confirmed</Badge>;
      case 'delivered':
      case 'completed':
        return <Badge tone="ok">Delivered</Badge>;
      case 'disputed':
        return <Badge tone="danger">Disputed</Badge>;
      case 'cancelled':
        return <Badge tone="danger">Cancelled</Badge>;
      default:
        return <Badge tone="warn">{status}</Badge>;
    }
  };

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="Live Shipments & Bookings Desk" 
          sub="End-to-end dispatch oversight of customer cargo requests, driver matching, and corridor trip fulfillment." 
        />
        <div className="flex items-center gap-2">
          <Button 
            variant="secondary" 
            onClick={loadData} 
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Feed</span>
          </Button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="mt-5 grid grid-cols-2 sm:grid-cols-4 gap-3">
        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">Total Bookings</span>
            <Package size={16} className="text-amber-400" />
          </div>
          <p className="text-2xl font-black text-white mt-1">{metrics.total}</p>
          <span className="text-[10px] text-slate-500">Live platform volume</span>
        </Card>

        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">In Transit</span>
            <Truck size={16} className="text-sky-400" />
          </div>
          <p className="text-2xl font-black text-sky-400 mt-1">{metrics.inTransit}</p>
          <span className="text-[10px] text-slate-500">Rolling on highway</span>
        </Card>

        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">Pickup Pending</span>
            <Clock size={16} className="text-amber-400" />
          </div>
          <p className="text-2xl font-black text-amber-400 mt-1">{metrics.pending}</p>
          <span className="text-[10px] text-slate-500">Awaiting cargo loading</span>
        </Card>

        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">Total Value</span>
            <CheckCircle2 size={16} className="text-emerald-400" />
          </div>
          <p className="text-2xl font-black text-emerald-400 mt-1">
            ₹{(metrics.totalFreight / 1000).toFixed(1)}k
          </p>
          <span className="text-[10px] text-slate-500">Gross freight value</span>
        </Card>
      </div>

      {/* Filter Tabs & Search Bar */}
      <div className="mt-6 flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="flex flex-wrap gap-1.5 p-1 bg-slate-900 border border-slate-800 rounded-xl">
          {[
            { id: "all", label: `All (${metrics.total})` },
            { id: "active", label: `Active (${metrics.pending + metrics.inTransit})` },
            { id: "in_transit", label: `In Transit (${metrics.inTransit})` },
            { id: "delivered", label: `Delivered (${metrics.completed})` },
            { id: "disputed", label: "Disputed" },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setStatusFilter(tab.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                statusFilter === tab.id
                  ? "bg-amber-400 text-slate-950 shadow-sm"
                  : "text-slate-400 hover:text-white"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div className="relative min-w-[260px]">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search booking, city, driver…"
            className="w-full pl-9 pr-3 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>
      </div>

      {/* Bookings Table */}
      <Card className="mt-4 p-0 bg-slate-900/90 border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        {loading ? (
          <div className="p-6"><CardSkeleton /></div>
        ) : filteredBookings.length === 0 ? (
          <div className="p-12 text-center text-slate-500 space-y-2">
            <Package size={36} className="mx-auto text-slate-600 mb-2" />
            <p className="font-bold text-slate-300">No shipments found</p>
            <p className="text-xs">
              {searchQuery ? "Try refining your search terms." : "Customer loads booked from redo_customer will appear here in real time."}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[1040px]">
              <thead className="bg-slate-950/60 border-b border-slate-800 text-[11px] font-black uppercase tracking-wider text-slate-400">
                <tr>
                  <th className="py-3 px-4">Booking ID</th>
                  <th className="py-3 px-4">Route & Corridor</th>
                  <th className="py-3 px-4">Shipper</th>
                  <th className="py-3 px-4">Cargo Specs</th>
                  <th className="py-3 px-4">Assigned Truck</th>
                  <th className="py-3 px-4">Agreed Freight</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4">Pickup OTP</th>
                  <th className="py-3 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60">
                {filteredBookings.map((b) => {
                  const cargo = b.cargo;
                  const truck = b.truck;
                  return (
                    <tr key={b.id} className="hover:bg-slate-800/30 transition">
                      <td className="py-3.5 px-4 font-mono font-bold text-amber-400">
                        {b.id.slice(0, 8)}…
                        <span className="block text-[10px] text-slate-500 font-sans font-normal mt-0.5">
                          {new Date(b.created_at).toLocaleDateString("en-IN", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-1.5 font-bold text-white text-xs">
                          <span>{cargo?.origin || "Origin Hub"}</span>
                          <ArrowRight size={12} className="text-amber-400" />
                          <span>{cargo?.destination || "Destination Hub"}</span>
                        </div>
                        <span className="text-[10px] text-slate-400 block mt-0.5">
                          {cargo?.distance_km ? `${cargo.distance_km} km` : "Standard Lane"}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        <span className="font-semibold text-slate-200">{cargo?.sme?.full_name || cargo?.sme?.company_name || "Unknown shipper"}</span>
                        <span className="block text-[10px] text-slate-400">{cargo?.sme?.phone || "No phone"}</span>
                      </td>

                      <td className="py-3.5 px-4">
                        <span className="font-semibold text-slate-200">
                          {cargo?.cargo_weight_tons ?? 1.5} Tons
                        </span>
                        <span className="block text-[10px] text-slate-400 capitalize">
                          {cargo?.cargo_type ? cargo.cargo_type.replaceAll('_', ' ') : "General Freight"}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        {truck ? (
                          <div>
                            <span className="font-mono font-bold text-white">
                              {truck.registration_number || truck.truck_id}
                            </span>
                            <span className="block text-[10px] text-slate-400">
                              {truck.truck_type} · {truck.default_capacity_tons}T
                            </span>
                          </div>
                        ) : (
                          <span className="text-slate-500 italic text-[11px]">Unassigned</span>
                        )}
                      </td>

                      <td className="py-3.5 px-4 font-bold text-emerald-400 text-sm">
                        ₹{Number(b.agreed_price_inr || 0).toLocaleString("en-IN")}
                      </td>

                      <td className="py-3.5 px-4">
                        {getStatusBadge(b.status)}
                      </td>

                      <td className="py-3.5 px-4">
                        {b.pickup_otp_verified_at
                          ? <Badge tone="ok">Verified</Badge>
                          : <Badge tone="warn">Pending</Badge>}
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <Button
                          variant="secondary"
                          onClick={() => setSelectedBooking(b)}
                          className="!py-1 !px-2.5 text-[11px] bg-slate-800 hover:bg-slate-700 text-slate-200 border-slate-700"
                        >
                          Manage
                        </Button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Details & Actions Modal */}
      {selectedBooking && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-lg bg-slate-900 border border-slate-800 rounded-3xl p-6 shadow-2xl relative">
            <div className="flex justify-between items-start mb-4">
              <div>
                <span className="text-[10px] font-mono text-amber-400 font-bold uppercase tracking-wider">
                  Booking #{selectedBooking.id}
                </span>
                <h3 className="text-lg font-black text-white mt-0.5">
                  Shipment Oversight & Override
                </h3>
              </div>
              <button
                onClick={() => setSelectedBooking(null)}
                className="text-slate-500 hover:text-white text-lg font-bold"
              >
                ✕
              </button>
            </div>

            <div className="space-y-4 text-xs">
              <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 space-y-2">
                <div className="flex justify-between text-slate-400">
                  <span>Current Status:</span>
                  <span>{getStatusBadge(selectedBooking.status)}</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Route:</span>
                  <span className="font-bold text-white">
                    {selectedBooking.cargo?.origin} ➔ {selectedBooking.cargo?.destination}
                  </span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Cargo Weight & Type:</span>
                  <span className="text-slate-300">
                    {selectedBooking.cargo?.cargo_weight_tons} Tons · {selectedBooking.cargo?.cargo_type}
                  </span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Agreed Price:</span>
                  <span className="font-bold text-emerald-400">
                    ₹{Number(selectedBooking.agreed_price_inr).toLocaleString("en-IN")}
                  </span>
                </div>
              </div>

              {/* Status Override Buttons */}
              <div>
                <p className="font-bold text-slate-300 mb-2">Admin Status Override:</p>
                <div className="grid grid-cols-2 gap-2">
                  <Button
                    onClick={() => handleUpdateStatus(selectedBooking.id, "picked_up")}
                    disabled={actionBusy}
                    className="bg-amber-500 hover:bg-amber-600 text-slate-950 font-bold py-2 rounded-xl text-xs"
                  >
                    Mark Picked Up
                  </Button>
                  <Button
                    onClick={() => handleUpdateStatus(selectedBooking.id, "in_transit")}
                    disabled={actionBusy}
                    className="bg-sky-500 hover:bg-sky-600 text-slate-950 font-bold py-2 rounded-xl text-xs"
                  >
                    Mark In Transit
                  </Button>
                  <Button
                    onClick={() => handleUpdateStatus(selectedBooking.id, "delivered")}
                    disabled={actionBusy}
                    className="bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold py-2 rounded-xl text-xs"
                  >
                    Mark Delivered
                  </Button>
                  <Button
                    onClick={() => handleUpdateStatus(selectedBooking.id, "cancelled")}
                    disabled={actionBusy}
                    variant="danger"
                    className="py-2 rounded-xl text-xs"
                  >
                    Cancel Booking
                  </Button>
                </div>
              </div>
            </div>

            <div className="mt-5 pt-3 border-t border-slate-800 flex justify-end">
              <Button
                variant="secondary"
                onClick={() => setSelectedBooking(null)}
                className="bg-slate-800 text-white border-slate-700"
              >
                Close
              </Button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
}
