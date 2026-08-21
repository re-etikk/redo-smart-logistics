import { useCallback, useEffect, useRef, useState } from "react";
import { useParams } from "react-router-dom";
import Layout from "../components/Layout";
import MapPanel, { CITIES } from "../components/MapPanel";
import { api } from "../services/api";
import { supabase } from "../lib/supabase";
import { Badge, Button, Card, CardSkeleton, statusLabel, statusTone, useToast } from "../components/ui";
import type { Booking } from "../lib/types";

export default function Tracking() {
  const { bookingId = "" } = useParams();
  const [booking, setBooking] = useState<Booking | null>(null);
  const [events, setEvents] = useState<any[]>([]);
  const [simRunning, setSimRunning] = useState(false);
  const simRef = useRef<number | null>(null);
  const toast = useToast();

  const load = useCallback(async () => {
    const [b, ev] = await Promise.all([
      api.get<Booking>(`/bookings/${bookingId}`),
      api.get<any[]>(`/tracking/${bookingId}`),
    ]);
    setBooking(b); setEvents(ev);
  }, [bookingId]);

  useEffect(() => { load().catch(() => {}); }, [load]);

  // Supabase Realtime: live tracking updates (§37/§38)
  useEffect(() => {
    const ch = supabase.channel(`tracking-${bookingId}`)
      .on("postgres_changes",
        { event: "INSERT", schema: "public", table: "tracking_events", filter: `booking_id=eq.${bookingId}` },
        (payload) => setEvents((ev) => [payload.new, ...ev]))
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [bookingId]);

  useEffect(() => () => { if (simRef.current) window.clearInterval(simRef.current); }, []);

  const startSimulation = () => {
    if (!booking || simRunning) return;
    setSimRunning(true);
    const a = CITIES[booking.cargo.origin] ?? [19, 72];
    const b = CITIES[booking.cargo.destination] ?? [28, 77];
    let step = Math.min(0.95, (events[0]?.progress_pct ?? 0) / 100 + 0.1);
    simRef.current = window.setInterval(async () => {
      const lat = a[0] + (b[0] - a[0]) * step;
      const lng = a[1] + (b[1] - a[1]) * step;
      try {
        await api.post(`/tracking/${bookingId}/events`, {
          lat, lng, progress_pct: Math.round(step * 100),
          eta_minutes: Math.round((1 - step) * 33 * 60), is_simulated: true,
        });
      } catch { /* backend enforces access */ }
      step += 0.1;
      if (step > 1) { window.clearInterval(simRef.current!); simRef.current = null; setSimRunning(false); toast("Simulated trip reached destination"); }
    }, 2500);
  };

  if (!booking) return <Layout><CardSkeleton /></Layout>;
  const latest = events[0];
  const pos: [number, number] | null = latest ? [Number(latest.lat), Number(latest.lng)] : null;

  return (
    <Layout>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-extrabold text-ink">Tracking</h1>
          <p className="text-sm text-ink-soft">{booking.cargo.origin} → {booking.cargo.destination} · {booking.truck.registration_number}</p>
        </div>
        <div className="flex items-center gap-2">
          <Badge tone="warn">Demo tracking · Simulated location</Badge>
          <Badge tone={statusTone(booking.status)}>{statusLabel(booking.status)}</Badge>
        </div>
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-[1fr_320px]">
        <MapPanel origin={booking.cargo.origin} destination={booking.cargo.destination} position={pos} heightClass="h-72 md:h-96" />
        <div className="space-y-4">
          <Card className="p-5">
            <h2 className="font-bold text-ink">Progress</h2>
            <p className="mt-2 text-3xl font-extrabold text-ink tabular-nums">{latest ? Math.round(latest.progress_pct) : 0}%</p>
            <p className="text-sm text-ink-faint">
              {latest ? `ETA ≈ ${Math.round(latest.eta_minutes / 60)} h · updated ${new Date(latest.timestamp).toLocaleTimeString("en-IN")}` : "No tracking events yet."}
            </p>
            <Button className="mt-4 w-full" variant="secondary" onClick={startSimulation} disabled={simRunning || ["completed","cancelled"].includes(booking.status)}>
              {simRunning ? "Simulating movement…" : "Simulate movement"}
            </Button>
            <p className="mt-2 text-[11px] text-ink-faint">
              Positions are simulated for demonstration and are stored as simulated events — never presented as real GPS.
            </p>
          </Card>
          <Card className="p-5">
            <h2 className="font-bold text-ink">Safety alerts</h2>
            <p className="mt-1 text-sm text-ink-faint">Delay, deviation and fatigue alerts — <span className="font-semibold">Coming soon</span>. Requires real telematics data.</p>
          </Card>
        </div>
      </div>
    </Layout>
  );
}
