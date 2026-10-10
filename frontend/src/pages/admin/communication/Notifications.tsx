import { useState, useEffect } from "react";
import { 
  Bell, Send, Users, Truck, Package, Search, RefreshCw, 
  CheckCircle2, Clock, Megaphone
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface NotificationItem {
  id: string;
  user_id: string;
  type: string;
  title: string;
  message: string;
  created_at: string;
  user?: {
    full_name: string;
    role: string;
    phone: string;
  };
}

export default function Notifications() {
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [broadcastModal, setBroadcastModal] = useState(false);
  const [target, setTarget] = useState<"all" | "drivers" | "shippers">("all");
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [successBanner, setSuccessBanner] = useState<string | null>(null);

  const fetchNotifications = async () => {
    setLoading(true);
    try {
      const data = await api.get<NotificationItem[]>("/admin/communication/notifications");
      setNotifications(data || []);
    } catch (err) {
      console.error("Error fetching notifications:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  const handleBroadcast = async () => {
    if (!title.trim() || !message.trim()) return;
    setSubmitting(true);
    try {
      const res = await api.post<any>("/admin/communication/broadcast", {
        target,
        title: title.trim(),
        message: message.trim(),
      });
      setBroadcastModal(false);
      setTitle("");
      setMessage("");
      setSuccessBanner(`Broadcast successfully dispatched to ${res.count || "active"} ${target} accounts.`);
      setTimeout(() => setSuccessBanner(null), 5000);
      await fetchNotifications();
    } catch (err) {
      console.error("Broadcast failed:", err);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="System Notifications & Broadcast Dispatch"
            sub="Dispatch corridor alerts and monitor automated push delivery for load matches, KYC updates, and payouts."
          />
          <div className="flex items-center gap-2">
            <Button
              variant="secondary"
              onClick={fetchNotifications}
              disabled={loading}
              className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
            >
              <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
              <span>Refresh Logs</span>
            </Button>
            <Button
              variant="primary"
              onClick={() => setBroadcastModal(true)}
              className="gap-1.5 bg-amber-400 text-slate-950 font-bold"
            >
              <Megaphone size={15} />
              <span>Broadcast Announcement</span>
            </Button>
          </div>
        </div>

        {/* Success Banner */}
        {successBanner && (
          <div className="p-3.5 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 text-xs font-semibold flex items-center gap-2">
            <CheckCircle2 size={16} />
            <span>{successBanner}</span>
          </div>
        )}

        {/* Recent Notifications Table */}
        <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
          {loading ? (
            <div className="p-6"><CardSkeleton /></div>
          ) : notifications.length === 0 ? (
            <div className="text-center py-12 text-slate-500 text-xs">
              No recent notifications dispatched.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-950/70 border-b border-slate-800 text-[10px] font-black uppercase text-slate-400 tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Event Type</th>
                    <th className="py-3 px-4">Notification Title</th>
                    <th className="py-3 px-4">Message Body</th>
                    <th className="py-3 px-4">Target User</th>
                    <th className="py-3 px-4 text-right">Dispatched At</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {notifications.map((n) => (
                    <tr key={n.id} className="hover:bg-slate-800/40 transition">
                      <td className="py-3 px-4">
                        <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-slate-800 text-amber-400 font-mono">
                          {n.type?.replace("_", " ") || "ALERT"}
                        </span>
                      </td>
                      <td className="py-3 px-4 font-bold text-white">
                        {n.title}
                      </td>
                      <td className="py-3 px-4 text-slate-300 max-w-xs truncate">
                        {n.message}
                      </td>
                      <td className="py-3 px-4">
                        <div className="text-slate-200 font-semibold">{n.user?.full_name || "User"}</div>
                        <div className="text-[10px] text-slate-500 uppercase">{n.user?.role || "Account"}</div>
                      </td>
                      <td className="py-3 px-4 text-right text-slate-400 font-mono text-[11px]">
                        {new Date(n.created_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>

        {/* Modal: Broadcast Announcement */}
        {broadcastModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs">
            <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-2xl space-y-4">
              <h3 className="text-sm font-black text-white flex items-center gap-2">
                <Megaphone size={16} className="text-amber-400" />
                <span>Dispatch Platform Broadcast</span>
              </h3>
              <p className="text-xs text-slate-400">
                Send an immediate operational push notification to drivers or shippers across active corridors.
              </p>

              <div className="space-y-3 text-xs">
                <div>
                  <label className="text-[10px] font-bold text-slate-400 block mb-1">Target Audience</label>
                  <div className="grid grid-cols-3 gap-2">
                    {[
                      { id: "all", label: "All Users" },
                      { id: "drivers", label: "Drivers Only" },
                      { id: "shippers", label: "Shippers Only" },
                    ].map((t) => (
                      <button
                        key={t.id}
                        type="button"
                        onClick={() => setTarget(t.id as any)}
                        className={`py-2 px-2 rounded-xl text-[11px] font-bold transition ${
                          target === t.id
                            ? "bg-amber-400 text-slate-950 font-black shadow-xs"
                            : "bg-slate-800 text-slate-400 hover:text-white"
                        }`}
                      >
                        {t.label}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="text-[10px] font-bold text-slate-400 block mb-1">Notification Title</label>
                  <input
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="e.g. NH48 Highway Construction Advisory"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2.5 text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
                  />
                </div>

                <div>
                  <label className="text-[10px] font-bold text-slate-400 block mb-1">Message Content</label>
                  <textarea
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    placeholder="Provide details regarding the alert or corridor incentive..."
                    rows={3}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2.5 text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <Button variant="secondary" onClick={() => setBroadcastModal(false)}>
                  Cancel
                </Button>
                <button
                  onClick={handleBroadcast}
                  disabled={submitting || !title.trim() || !message.trim()}
                  className="px-4 py-2 rounded-xl bg-amber-400 hover:bg-amber-500 disabled:opacity-40 text-slate-950 font-black text-xs transition"
                >
                  Send Broadcast
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
}
