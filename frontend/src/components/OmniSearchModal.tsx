import { useState, useEffect, useRef } from "react";
import { Search, X, Package, Truck, Users, HelpCircle, ArrowRight, Loader2 } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { api } from "../services/api";

interface OmniSearchModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function OmniSearchModal({ isOpen, onClose }: OmniSearchModalProps) {
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState<any>({ shipments: [], trucks: [], users: [], tickets: [], total: 0 });
  const navigate = useNavigate();
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 50);
    } else {
      setQuery("");
      setResults({ shipments: [], trucks: [], users: [], tickets: [], total: 0 });
    }
  }, [isOpen]);

  useEffect(() => {
    if (!query.trim() || query.trim().length < 2) {
      setResults({ shipments: [], trucks: [], users: [], tickets: [], total: 0 });
      return;
    }

    const timer = setTimeout(async () => {
      setLoading(true);
      try {
        const res = await api.get(`/admin/search?q=${encodeURIComponent(query.trim())}`);
        setResults(res || { shipments: [], trucks: [], users: [], tickets: [], total: 0 });
      } catch (err) {
        console.error("Search error:", err);
      } finally {
        setLoading(false);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [query]);

  if (!isOpen) return null;

  const handleSelect = (path: string) => {
    onClose();
    navigate(path);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-16 px-4 bg-slate-950/80 backdrop-blur-sm animate-in fade-in duration-200">
      <div 
        className="w-full max-w-2xl bg-slate-900 border border-slate-800 rounded-2xl shadow-2xl shadow-black/60 overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Search Input Bar */}
        <div className="flex items-center px-4 py-3.5 border-b border-slate-800 gap-3">
          <Search size={20} className="text-amber-400 shrink-0" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search shipments, truck numbers, shippers, tickets..."
            className="flex-1 bg-transparent text-sm text-white placeholder-slate-500 focus:outline-none"
          />
          {loading && <Loader2 size={16} className="text-amber-400 animate-spin" />}
          {query && (
            <button onClick={() => setQuery("")} className="text-slate-500 hover:text-slate-300">
              <X size={16} />
            </button>
          )}
          <kbd className="hidden sm:inline-block px-1.5 py-0.5 text-[10px] font-bold text-slate-400 bg-slate-800 border border-slate-700 rounded">
            ESC
          </kbd>
        </div>

        {/* Results Body */}
        <div className="max-h-[60vh] overflow-y-auto p-3 space-y-4">
          {query.trim().length >= 2 && results.total === 0 && !loading && (
            <div className="text-center py-8 text-xs text-slate-500">
              No results found matching "{query}".
            </div>
          )}

          {/* Shipments */}
          {results.shipments?.length > 0 && (
            <div>
              <div className="px-2 pb-1.5 text-[10px] font-black uppercase tracking-wider text-slate-500 flex items-center gap-1.5">
                <Package size={12} className="text-amber-400" />
                <span>Shipments & Cargo</span>
              </div>
              <div className="space-y-1">
                {results.shipments.map((s: any) => (
                  <button
                    key={s.cargo_id}
                    onClick={() => handleSelect(`/admin/bookings?search=${s.cargo_id}`)}
                    className="w-full text-left p-2.5 rounded-xl hover:bg-slate-800/80 transition flex items-center justify-between group"
                  >
                    <div>
                      <div className="text-xs font-bold text-slate-200 group-hover:text-amber-400 transition">
                        #{s.cargo_id} — {s.origin} → {s.destination}
                      </div>
                      <div className="text-[11px] text-slate-400">
                        {s.cargo_type} • Status: <span className="uppercase text-amber-300 font-semibold">{s.status}</span>
                      </div>
                    </div>
                    <ArrowRight size={14} className="text-slate-600 group-hover:text-amber-400 group-hover:translate-x-0.5 transition" />
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Trucks */}
          {results.trucks?.length > 0 && (
            <div>
              <div className="px-2 pb-1.5 text-[10px] font-black uppercase tracking-wider text-slate-500 flex items-center gap-1.5">
                <Truck size={12} className="text-emerald-400" />
                <span>Commercial Fleet</span>
              </div>
              <div className="space-y-1">
                {results.trucks.map((t: any) => (
                  <button
                    key={t.truck_id}
                    onClick={() => handleSelect(`/admin/radar?truck=${t.truck_id}`)}
                    className="w-full text-left p-2.5 rounded-xl hover:bg-slate-800/80 transition flex items-center justify-between group"
                  >
                    <div>
                      <div className="text-xs font-bold text-slate-200 group-hover:text-emerald-400 transition">
                        {t.registration_number} ({t.truck_type})
                      </div>
                      <div className="text-[11px] text-slate-400">
                        Origin: {t.home_origin || "Unassigned"} • Status: <span className="uppercase text-emerald-300 font-semibold">{t.status}</span>
                      </div>
                    </div>
                    <ArrowRight size={14} className="text-slate-600 group-hover:text-emerald-400 group-hover:translate-x-0.5 transition" />
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Users */}
          {results.users?.length > 0 && (
            <div>
              <div className="px-2 pb-1.5 text-[10px] font-black uppercase tracking-wider text-slate-500 flex items-center gap-1.5">
                <Users size={12} className="text-sky-400" />
                <span>Platform Users</span>
              </div>
              <div className="space-y-1">
                {results.users.map((u: any) => (
                  <button
                    key={u.id}
                    onClick={() => handleSelect(`/admin/users?q=${u.full_name}`)}
                    className="w-full text-left p-2.5 rounded-xl hover:bg-slate-800/80 transition flex items-center justify-between group"
                  >
                    <div>
                      <div className="text-xs font-bold text-slate-200 group-hover:text-sky-400 transition">
                        {u.full_name || u.company_name} ({u.role?.toUpperCase()})
                      </div>
                      <div className="text-[11px] text-slate-400">
                        {u.company_name ? `${u.company_name} • ` : ""}{u.phone ? `+91 ••••• ••${u.phone.slice(-3)}` : "No phone"}
                      </div>
                    </div>
                    <ArrowRight size={14} className="text-slate-600 group-hover:text-sky-400 group-hover:translate-x-0.5 transition" />
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Support Tickets */}
          {results.tickets?.length > 0 && (
            <div>
              <div className="px-2 pb-1.5 text-[10px] font-black uppercase tracking-wider text-slate-500 flex items-center gap-1.5">
                <HelpCircle size={12} className="text-rose-400" />
                <span>Support Tickets</span>
              </div>
              <div className="space-y-1">
                {results.tickets.map((tk: any) => (
                  <button
                    key={tk.id}
                    onClick={() => handleSelect(`/admin/communication/tickets?id=${tk.id}`)}
                    className="w-full text-left p-2.5 rounded-xl hover:bg-slate-800/80 transition flex items-center justify-between group"
                  >
                    <div>
                      <div className="text-xs font-bold text-slate-200 group-hover:text-rose-400 transition">
                        #{tk.id} — {tk.subject}
                      </div>
                      <div className="text-[11px] text-slate-400">
                        Priority: <span className="uppercase text-rose-300 font-semibold">{tk.priority}</span> • From: {tk.user_name}
                      </div>
                    </div>
                    <ArrowRight size={14} className="text-slate-600 group-hover:text-rose-400 group-hover:translate-x-0.5 transition" />
                  </button>
                ))}
              </div>
            </div>
          )}

          {!query && (
            <div className="p-4 text-center">
              <p className="text-xs text-slate-400">Quick Searches:</p>
              <div className="mt-2 flex flex-wrap justify-center gap-2">
                {["Delhi", "Mumbai", "In Transit", "Pending KYC", "Refund"].map((tag) => (
                  <button
                    key={tag}
                    onClick={() => setQuery(tag)}
                    className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-[11px] font-medium text-slate-300 border border-slate-700 transition"
                  >
                    {tag}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="p-3 bg-slate-950/60 border-t border-slate-800 text-[11px] text-slate-500 flex justify-between items-center">
          <span>Global REDO Logistics Search</span>
          <button onClick={onClose} className="hover:text-slate-300">Close</button>
        </div>
      </div>
    </div>
  );
}
