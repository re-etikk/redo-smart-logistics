import { useEffect, useState } from "react";
import { CalendarCheck, FileClock, Truck, Users } from "lucide-react";
import Layout from "../../components/Layout";
import { api } from "../../services/api";
import { Card, CardSkeleton, SectionHead, StatCard } from "../../components/ui";

export default function AdminDashboard() {
  const [stats, setStats] = useState<any | null>(null);
  useEffect(() => { api.get("/admin/stats").then(setStats).catch(() => setStats({})); }, []);
  return (
    <Layout>
      <SectionHead title="Operations Dashboard" sub="Platform overview for the Redo operations team." />
      {stats === null ? <div className="mt-5"><CardSkeleton /></div> : (
        <div className="mt-5 grid gap-4 grid-cols-2 xl:grid-cols-4">
          <StatCard icon={Users} label="Total Users" value={stats.users ?? 0} sub={`${stats.shippers ?? 0} shippers · ${stats.owners ?? 0} owners`} tone="info" />
          <StatCard icon={Truck} label="Trucks" value={stats.trucks ?? 0} tone="ok" />
          <StatCard icon={CalendarCheck} label="Bookings" value={stats.bookings ?? 0} sub={`${stats.completed ?? 0} completed`} tone="purple" />
          <StatCard icon={FileClock} label="KYC Pending" value={stats.kyc_pending ?? 0} sub="Awaiting review" tone="warn" />
        </div>
      )}
      <Card className="mt-5 p-5">
        <p className="text-sm text-ink-soft">
          Use <span className="font-semibold">Users</span> to view and manage accounts, and{" "}
          <span className="font-semibold">KYC Verification</span> to approve or reject uploaded documents.
        </p>
      </Card>
    </Layout>
  );
}
