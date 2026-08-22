import { useEffect, useState } from "react";
import { CalendarCheck, Clock, IndianRupee, TrendingUp } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Badge, Card, CardSkeleton, EmptyState, SectionHead, StatCard } from "../../components/ui";

export default function Earnings() {
  const [data, setData] = useState<any | null>(null);
  useEffect(() => { api.get("/earnings").then(setData).catch(() => setData({ totals: {}, transactions: [] })); }, []);
  const t = data?.totals ?? {};
  const txns: any[] = data?.transactions ?? [];

  return (
    <Layout>
      <SectionHead title="Earnings" sub="Track your earnings, payouts and performance." />
      <div className="mt-5 grid gap-4 grid-cols-2 xl:grid-cols-4">
        <StatCard icon={IndianRupee} label="Total Earnings" value={`₹${Number(t.completed_inr ?? 0).toLocaleString("en-IN")}`} tone="ok" />
        <StatCard icon={CalendarCheck} label="Completed Trips" value={t.completed_trips ?? 0} tone="info" />
        <StatCard icon={TrendingUp} label="Average Per Trip" value={`₹${Number(t.avg_per_trip_inr ?? 0).toLocaleString("en-IN")}`} tone="purple" />
        <StatCard icon={Clock} label="Pending Amount" value={`₹${Number(t.pending_inr ?? 0).toLocaleString("en-IN")}`} sub={`${t.pending_trips ?? 0} trips in progress`} tone="warn" />
      </div>
      <Card className="mt-5 p-5">
        <h2 className="font-bold text-ink">Earnings Transactions</h2>
        {data === null ? <div className="mt-3"><CardSkeleton /></div> : txns.length === 0 ? (
          <div className="mt-3"><EmptyState title="No earnings yet." hint="Complete trips to see payouts here. Amounts settle when the shipper confirms delivery." /></div>
        ) : (
          <div className="mt-2 overflow-x-auto">
            <table className="w-full text-sm min-w-[640px]">
              <thead><tr className="text-left text-xs font-semibold text-ink-faint border-b border-line">
                <th className="py-2.5 pr-3">Date</th><th className="py-2.5 pr-3">Booking</th>
                <th className="py-2.5 pr-3">Trip Route</th><th className="py-2.5 pr-3">Amount</th><th className="py-2.5">Status</th>
              </tr></thead>
              <tbody>
                {txns.map((x) => (
                  <tr key={x.booking_id} className="border-b border-line last:border-0">
                    <td className="py-3.5 pr-3 text-ink-soft">{new Date(x.date).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })}</td>
                    <td className="py-3.5 pr-3 font-bold text-accent">{x.cargo_id}</td>
                    <td className="py-3.5 pr-3 font-semibold">{x.route}</td>
                    <td className="py-3.5 pr-3 font-bold tabular-nums">₹{Number(x.amount_inr).toLocaleString("en-IN")}</td>
                    <td className="py-3.5"><Badge tone={x.settled ? "ok" : "warn"}>{x.settled ? "Paid" : "Pending"}</Badge></td>
                  </tr>
                ))}
              </tbody>
            </table>
            <p className="mt-3 text-xs text-ink-faint">Settlement shown here is derived from booking status (completed = paid). Real payout rails plug in later.</p>
          </div>
        )}
      </Card>
    </Layout>
  );
}
