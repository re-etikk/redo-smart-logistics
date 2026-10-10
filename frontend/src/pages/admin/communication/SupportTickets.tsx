import { useState, useEffect } from "react";
import { 
  LifeBuoy, AlertCircle, CheckCircle2, Clock, Search, RefreshCw, 
  Eye, Plus, MessageSquare, UserCheck, ShieldAlert
} from "lucide-react";
import Layout from "../../../components/Layout";
import { api } from "../../../services/api";
import { Card, SectionHead, Button, CardSkeleton } from "../../../components/ui";

interface TicketItem {
  id: string;
  user_id: string;
  user_name: string;
  user_role: string;
  category: string;
  priority: "low" | "medium" | "high" | "critical";
  status: "open" | "assigned" | "in_progress" | "waiting_for_user" | "resolved" | "closed";
  subject: string;
  description: string;
  assigned_to: string | null;
  internal_notes: string | null;
  created_at: string;
  updated_at: string;
}

export default function SupportTickets() {
  const [tickets, setTickets] = useState<TicketItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterTab, setFilterTab] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTicket, setSelectedTicket] = useState<TicketItem | null>(null);
  const [newTicketModal, setNewTicketModal] = useState(false);
  const [subjectInput, setSubjectInput] = useState("");
  const [descInput, setDescInput] = useState("");
  const [categoryInput, setCategoryInput] = useState("general");
  const [priorityInput, setPriorityInput] = useState("medium");
  const [internalNotes, setInternalNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const fetchTickets = async () => {
    setLoading(true);
    try {
      const data = await api.get<TicketItem[]>("/admin/tickets");
      setTickets(data || []);
    } catch (err) {
      console.error("Error fetching tickets:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTickets();
  }, []);

  const handleUpdateStatus = async (ticketId: string, status: string) => {
    setSubmitting(true);
    try {
      await api.patch(`/admin/tickets/${ticketId}`, { status });
      await fetchTickets();
      if (selectedTicket?.id === ticketId) {
        setSelectedTicket((prev) => prev ? { ...prev, status: status as any } : null);
      }
    } catch (err) {
      console.error("Failed to update status:", err);
    } finally {
      setSubmitting(false);
    }
  };

  const handleSaveNotes = async () => {
    if (!selectedTicket) return;
    setSubmitting(true);
    try {
      await api.patch(`/admin/tickets/${selectedTicket.id}`, { internal_notes: internalNotes });
      await fetchTickets();
      setSelectedTicket((prev) => prev ? { ...prev, internal_notes: internalNotes } : null);
    } catch (err) {
      console.error("Failed to save notes:", err);
    } finally {
      setSubmitting(false);
    }
  };

  const handleCreateTicket = async () => {
    if (!subjectInput.trim() || !descInput.trim()) return;
    setSubmitting(true);
    try {
      await api.post("/admin/tickets", {
        subject: subjectInput.trim(),
        description: descInput.trim(),
        category: categoryInput,
        priority: priorityInput,
      });
      setNewTicketModal(false);
      setSubjectInput("");
      setDescInput("");
      await fetchTickets();
    } catch (err) {
      console.error("Failed to create ticket:", err);
    } finally {
      setSubmitting(false);
    }
  };

  const filteredTickets = tickets.filter((t) => {
    if (filterTab === "open" && ["resolved", "closed"].includes(t.status)) return false;
    if (filterTab === "resolved" && !["resolved", "closed"].includes(t.status)) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        t.subject.toLowerCase().includes(q) ||
        t.id.toLowerCase().includes(q) ||
        t.user_name?.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const getPriorityBadge = (p: string) => {
    switch (p) {
      case "critical":
        return <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-rose-500/20 text-rose-400 border border-rose-500/30">CRITICAL</span>;
      case "high":
        return <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-amber-500/20 text-amber-400 border border-amber-500/30">HIGH</span>;
      case "medium":
        return <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-sky-500/20 text-sky-400 border border-sky-500/30">MEDIUM</span>;
      default:
        return <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-slate-500/20 text-slate-400 border border-slate-500/30">LOW</span>;
    }
  };

  return (
    <Layout>
      <div className="space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SectionHead
            title="Support Tickets & Escalation Desk"
            sub="Resolve shipper queries, payout settlement disputes, and driver assistance requests."
          />
          <div className="flex items-center gap-2">
            <Button
              variant="secondary"
              onClick={fetchTickets}
              disabled={loading}
              className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
            >
              <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
              <span>Refresh Queue</span>
            </Button>
            <Button
              variant="primary"
              onClick={() => setNewTicketModal(true)}
              className="gap-1.5 bg-amber-400 text-slate-950 font-bold"
            >
              <Plus size={15} />
              <span>New Ticket</span>
            </Button>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="flex items-center gap-2 border-b border-slate-800 pb-2 text-xs">
          {[
            { id: "all", label: "All Tickets", count: tickets.length },
            { id: "open", label: "Open & In-Progress", count: tickets.filter(t => !["resolved", "closed"].includes(t.status)).length },
            { id: "resolved", label: "Resolved", count: tickets.filter(t => ["resolved", "closed"].includes(t.status)).length },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilterTab(tab.id)}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-xl transition ${
                filterTab === tab.id
                  ? "bg-amber-400 text-slate-950 font-bold"
                  : "text-slate-400 hover:text-white hover:bg-slate-900"
              }`}
            >
              <span>{tab.label}</span>
              <span className={`px-1.5 py-0.2 rounded-full text-[10px] font-black ${
                filterTab === tab.id ? "bg-slate-950 text-amber-400" : "bg-slate-800 text-slate-400"
              }`}>
                {tab.count}
              </span>
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="relative">
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search tickets by subject, ticket ID, or user..."
            className="w-full bg-slate-900 border border-slate-800 rounded-xl pl-9 pr-3 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        {/* Table & Detail Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <div className={selectedTicket ? "lg:col-span-7" : "lg:col-span-12"}>
            <Card className="border border-slate-800 rounded-2xl bg-slate-900/90 overflow-hidden shadow-xl">
              {loading ? (
                <div className="p-6"><CardSkeleton /></div>
              ) : filteredTickets.length === 0 ? (
                <div className="text-center py-12 text-slate-500 text-xs">
                  No tickets found matching the selected filter.
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-950/70 border-b border-slate-800 text-[10px] font-black uppercase text-slate-400 tracking-wider">
                      <tr>
                        <th className="py-3 px-4">Ticket</th>
                        <th className="py-3 px-4">Initiator</th>
                        <th className="py-3 px-4">Category</th>
                        <th className="py-3 px-4">Priority</th>
                        <th className="py-3 px-4">Status</th>
                        <th className="py-3 px-4 text-right">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/60">
                      {filteredTickets.map((t) => {
                        const isSelected = selectedTicket?.id === t.id;
                        return (
                          <tr
                            key={t.id}
                            onClick={() => {
                              setSelectedTicket(t);
                              setInternalNotes(t.internal_notes || "");
                            }}
                            className={`cursor-pointer transition ${
                              isSelected ? "bg-amber-500/10" : "hover:bg-slate-800/40"
                            }`}
                          >
                            <td className="py-3 px-4">
                              <div className="font-mono font-bold text-white">#{t.id}</div>
                              <div className="text-[11px] text-slate-300 truncate max-w-[200px]">{t.subject}</div>
                            </td>
                            <td className="py-3 px-4">
                              <div className="text-slate-200 font-semibold">{t.user_name}</div>
                              <div className="text-[10px] text-slate-500 uppercase">{t.user_role}</div>
                            </td>
                            <td className="py-3 px-4">
                              <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-slate-800 text-slate-300">
                                {t.category}
                              </span>
                            </td>
                            <td className="py-3 px-4">{getPriorityBadge(t.priority)}</td>
                            <td className="py-3 px-4">
                              <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${
                                t.status === "resolved"
                                  ? "bg-emerald-500/15 text-emerald-400 border border-emerald-500/30"
                                  : t.status === "in_progress"
                                  ? "bg-sky-500/15 text-sky-400 border border-sky-500/30"
                                  : "bg-amber-500/15 text-amber-400 border border-amber-500/30"
                              }`}>
                                {t.status.replace("_", " ")}
                              </span>
                            </td>
                            <td className="py-3 px-4 text-right">
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setSelectedTicket(t);
                                  setInternalNotes(t.internal_notes || "");
                                }}
                                className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition"
                              >
                                <Eye size={14} />
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </Card>
          </div>

          {/* Ticket Detail Drawer */}
          {selectedTicket && (
            <div className="lg:col-span-5">
              <Card className="p-5 border border-slate-800 rounded-2xl bg-slate-900 sticky top-20 shadow-2xl space-y-4">
                <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                  <div>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Ticket Escalation</span>
                    <h3 className="text-base font-black text-white font-mono">#{selectedTicket.id}</h3>
                    <p className="text-xs text-slate-200 font-semibold mt-0.5">{selectedTicket.subject}</p>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    {getPriorityBadge(selectedTicket.priority)}
                    <span className="text-[10px] text-slate-500">Cat: {selectedTicket.category.toUpperCase()}</span>
                  </div>
                </div>

                {/* Description */}
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800 text-xs text-slate-300 leading-relaxed">
                  {selectedTicket.description}
                </div>

                {/* Status Switcher Buttons */}
                <div>
                  <h4 className="text-[10px] font-black uppercase text-slate-500 mb-1.5">
                    Ticket Lifecycle State
                  </h4>
                  <div className="grid grid-cols-3 gap-1.5 text-xs">
                    {(["open", "in_progress", "resolved"] as const).map((st) => (
                      <button
                        key={st}
                        onClick={() => handleUpdateStatus(selectedTicket.id, st)}
                        disabled={submitting}
                        className={`py-1.5 px-2 rounded-xl text-[11px] font-bold capitalize transition ${
                          selectedTicket.status === st
                            ? "bg-amber-400 text-slate-950 font-black shadow-xs"
                            : "bg-slate-800 text-slate-400 hover:text-white"
                        }`}
                      >
                        {st.replace("_", " ")}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Internal Admin Notes */}
                <div className="space-y-1.5">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-black uppercase text-slate-500">Internal Operational Notes</span>
                    <button
                      onClick={handleSaveNotes}
                      disabled={submitting}
                      className="text-[10px] font-bold text-amber-400 hover:underline"
                    >
                      Save Notes
                    </button>
                  </div>
                  <textarea
                    value={internalNotes}
                    onChange={(e) => setInternalNotes(e.target.value)}
                    placeholder="Log internal resolution steps, phone confirmation, or settlement batch number..."
                    rows={3}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
                  />
                </div>
              </Card>
            </div>
          )}
        </div>

        {/* Modal: Create Ticket */}
        {newTicketModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs">
            <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-2xl space-y-4">
              <h3 className="text-sm font-black text-white">Create Operations Support Ticket</h3>

              <div className="space-y-3 text-xs">
                <div>
                  <label className="text-[10px] font-bold text-slate-400 block mb-1">Subject</label>
                  <input
                    type="text"
                    value={subjectInput}
                    onChange={(e) => setSubjectInput(e.target.value)}
                    placeholder="e.g. Delayed bank settlement for booking..."
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2.5 text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
                  />
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="text-[10px] font-bold text-slate-400 block mb-1">Category</label>
                    <select
                      value={categoryInput}
                      onChange={(e) => setCategoryInput(e.target.value)}
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2 text-white focus:outline-none"
                    >
                      <option value="payment">Payment & Payout</option>
                      <option value="tracking">Live Tracking</option>
                      <option value="damage">Damage Claim</option>
                      <option value="verification">Verification</option>
                      <option value="general">General Support</option>
                    </select>
                  </div>

                  <div>
                    <label className="text-[10px] font-bold text-slate-400 block mb-1">Priority</label>
                    <select
                      value={priorityInput}
                      onChange={(e) => setPriorityInput(e.target.value)}
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2 text-white focus:outline-none"
                    >
                      <option value="low">Low</option>
                      <option value="medium">Medium</option>
                      <option value="high">High</option>
                      <option value="critical">Critical</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="text-[10px] font-bold text-slate-400 block mb-1">Description</label>
                  <textarea
                    value={descInput}
                    onChange={(e) => setDescInput(e.target.value)}
                    placeholder="Detail the issue reported by the shipper or fleet partner..."
                    rows={3}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2.5 text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <Button variant="secondary" onClick={() => setNewTicketModal(false)}>
                  Cancel
                </Button>
                <button
                  onClick={handleCreateTicket}
                  disabled={submitting || !subjectInput.trim() || !descInput.trim()}
                  className="px-4 py-2 rounded-xl bg-amber-400 hover:bg-amber-500 disabled:opacity-40 text-slate-950 font-black text-xs transition"
                >
                  Create Ticket
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
}
