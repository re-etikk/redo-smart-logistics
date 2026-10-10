import { useState, useEffect } from "react";
import { 
  PhoneCall, PhoneIncoming, PhoneOutgoing, PhoneMissed, PhoneOff, 
  Search, RefreshCw, Clock, ShieldCheck
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface CallLogItem {
  id: string;
  booking_id: string;
  caller_name: string;
  caller_role: string;
  caller_phone?: string;
  receiver_name: string;
  receiver_phone?: string;
  status: "calling" | "ringing" | "accepted" | "declined" | "missed" | "ended";
  duration_seconds: number;
  channel_name: string;
  started_at: string;
  ended_at?: string;
}

export default function CallLogs() {
  const [calls, setCalls] = useState<CallLogItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");

  const fetchCalls = async () => {
    setLoading(true);
    try {
      const data = await api.get<CallLogItem[]>("/admin/communication/calls");
      setCalls(data || []);
    } catch (err) {
      console.error("Error fetching call logs:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCalls();
  }, []);

  const filteredCalls = calls.filter((c) => {
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        c.caller_name.toLowerCase().includes(q) ||
        c.receiver_name.toLowerCase().includes(q) ||
        c.booking_id.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const formatDuration = (secs: number) => {
    if (!secs) return "0s";
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return m > 0 ? `${m}m ${s}s` : `${s}s`;
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "accepted":
      case "ended":
        return <PhoneCall size={14} className="text-emerald-400" />;
      case "missed":
        return <PhoneMissed size={14} className="text-rose-400" />;
      case "declined":
        return <PhoneOff size={14} className="text-amber-400" />;
      default:
        return <PhoneIncoming size={14} className="text-sky-400 animate-pulse" />;
    }
  };

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="In-App Voice Signaling Logs"
            sub="Audited record of peer-to-peer VoIP audio calls between shippers and drivers for active deliveries."
          />
          <Button
            variant="secondary"
            onClick={fetchCalls}
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh Call Log</span>
          </Button>
        </div>

        {/* Privacy Note */}
        <div className="p-3.5 rounded-xl bg-slate-900/80 border border-slate-800 flex items-center justify-between text-xs">
          <div className="flex items-center gap-2 text-slate-300">
            <ShieldCheck size={16} className="text-amber-400" />
            <span>DPDP Act Compliance: Driver & Shipper direct telephone numbers are masked across admin logs.</span>
          </div>
          <span className="text-[10px] font-bold text-slate-500 uppercase">VoIP Call Relay Active</span>
        </div>

        {/* Search */}
        <div className="relative">
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search calls by caller, receiver, or booking ID..."
            className="w-full bg-slate-900 border border-slate-800 rounded-xl pl-9 pr-3 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        {/* Call Logs Table */}
        <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
          {loading ? (
            <div className="p-6"><CardSkeleton /></div>
          ) : filteredCalls.length === 0 ? (
            <div className="text-center py-12 text-slate-500 text-xs">
              No recent VoIP calls logged.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-950/70 border-b border-slate-800 text-[10px] font-black uppercase text-slate-400 tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Call Event</th>
                    <th className="py-3 px-4">Caller (Initiator)</th>
                    <th className="py-3 px-4">Receiver</th>
                    <th className="py-3 px-4">Booking</th>
                    <th className="py-3 px-4">Duration</th>
                    <th className="py-3 px-4">Timestamp</th>
                    <th className="py-3 px-4 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {filteredCalls.map((c) => (
                    <tr key={c.id} className="hover:bg-slate-800/40 transition">
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-2">
                          {getStatusIcon(c.status)}
                          <span className="font-mono text-slate-300">#{c.id.slice(-6)}</span>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="font-bold text-white">{c.caller_name}</div>
                        <div className="text-[10px] text-slate-400">{c.caller_role} • {c.caller_phone}</div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="font-bold text-slate-200">{c.receiver_name}</div>
                        <div className="text-[10px] text-slate-400">{c.receiver_phone}</div>
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-400">
                        #{c.booking_id ? c.booking_id.slice(-6) : "RELAY"}
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-300">
                        {formatDuration(c.duration_seconds)}
                      </td>
                      <td className="py-3 px-4 text-slate-400">
                        {new Date(c.started_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })}
                      </td>
                      <td className="py-3 px-4 text-right">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${
                          c.status === "accepted" || c.status === "ended"
                            ? "bg-emerald-500/15 text-emerald-400 border border-emerald-500/30"
                            : c.status === "missed"
                            ? "bg-rose-500/15 text-rose-400 border border-rose-500/30"
                            : "bg-amber-500/15 text-amber-400 border border-amber-500/30"
                        }`}>
                          {c.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </div>
    </Layout>
  );
}
