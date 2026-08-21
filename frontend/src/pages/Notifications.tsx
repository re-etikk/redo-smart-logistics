import { useEffect, useState } from "react";
import Layout from "../components/Layout";
import { api } from "../services/api";
import { Card, CardSkeleton, EmptyState } from "../components/ui";

export default function Notifications() {
  const [items, setItems] = useState<any[] | null>(null);
  const load = () => api.get<any[]>("/notifications").then(setItems).catch(() => setItems([]));
  useEffect(() => { load(); }, []);
  const markRead = async (id: string) => { await api.patch(`/notifications/${id}/read`, {}); load(); };
  return (
    <Layout>
      <h1 className="text-2xl font-extrabold text-ink">Notifications</h1>
      <div className="mt-6 grid gap-3">
        {items === null && <CardSkeleton />}
        {items?.length === 0 && <EmptyState title="No notifications yet." />}
        {items?.map((n) => (
          <Card key={n.id} className={`p-4 ${n.read ? "opacity-60" : ""}`} role="button" tabIndex={0}
            onClick={() => !n.read && markRead(n.id)}>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="font-semibold text-ink text-sm">{n.title}</p>
                <p className="text-sm text-ink-soft">{n.message}</p>
              </div>
              <span className="text-xs text-ink-faint whitespace-nowrap">{new Date(n.created_at).toLocaleString("en-IN", { dateStyle: "short", timeStyle: "short" })}</span>
            </div>
          </Card>
        ))}
      </div>
    </Layout>
  );
}
