import { useState, useRef, useEffect } from "react";
import { Sparkles, X, Send, Bot, User, ArrowRight, ShieldCheck, Activity, Package, AlertTriangle, Loader2 } from "lucide-react";
import { api } from "../services/api";

interface Message {
  role: "user" | "assistant";
  text: string;
  insights?: string[];
  metrics?: any;
  timestamp: string;
}

interface OperationsAiDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function OperationsAiDrawer({ isOpen, onClose }: OperationsAiDrawerProps) {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: "assistant",
      text: "Hello, Administrator. I am your REDO Operations Copilot. Ask me about live freight corridor telemetry, driver KYC backlogs, stale GPS signals, or dynamic pricing parameters.",
      insights: [
        "Network telemetry is operating with live database grounding.",
        "Use suggested prompts below to run immediate operations audits.",
      ],
      timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
    },
  ]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, loading]);

  const handleSend = async (queryText?: string) => {
    const textToSend = queryText || input;
    if (!textToSend.trim() || loading) return;

    const userMsg: Message = {
      role: "user",
      text: textToSend.trim(),
      timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
    };

    setMessages((prev) => [...prev, userMsg]);
    if (!queryText) setInput("");
    setLoading(true);

    try {
      const res = await api.post<any>("/admin/ai/copilot", { query: textToSend.trim() });
      const assistantMsg: Message = {
        role: "assistant",
        text: res.answer || "Operations telemetry query executed successfully.",
        insights: res.insights || [],
        metrics: res.metrics,
        timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
      };
      setMessages((prev) => [...prev, assistantMsg]);
    } catch (err: any) {
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          text: "Error contacting REDO Operations telemetry service. Please verify backend connection.",
          timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
      <div 
        className="w-full max-w-md bg-slate-950 border-l border-slate-800 h-full flex flex-col shadow-2xl animate-in slide-in-from-right duration-300"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-900/80">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-amber-400 text-slate-950 flex items-center justify-center font-black shadow-md shadow-amber-400/20">
              <Sparkles size={18} />
            </div>
            <div>
              <h2 className="text-sm font-black text-white flex items-center gap-2">
                REDO Operations AI
                <span className="px-1.5 py-0.5 rounded bg-amber-500/20 border border-amber-500/30 text-[9px] font-bold text-amber-400">
                  COPILOT
                </span>
              </h2>
              <p className="text-[10px] text-slate-400">Live Logistics Telemetry Assistant</p>
            </div>
          </div>
          <button 
            onClick={onClose} 
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
          >
            <X size={18} />
          </button>
        </div>

        {/* Message Thread */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map((m, idx) => (
            <div 
              key={idx} 
              className={`flex flex-col ${m.role === "user" ? "items-end" : "items-start"}`}
            >
              <div className="flex items-center gap-1.5 mb-1 px-1">
                {m.role === "user" ? (
                  <>
                    <span className="text-[10px] font-semibold text-slate-400">{m.timestamp}</span>
                    <span className="text-[10px] font-black text-amber-400">You (Admin)</span>
                  </>
                ) : (
                  <>
                    <span className="text-[10px] font-black text-amber-400">REDO Copilot</span>
                    <span className="text-[10px] font-semibold text-slate-400">{m.timestamp}</span>
                  </>
                )}
              </div>

              <div 
                className={`p-3.5 rounded-2xl text-xs leading-relaxed max-w-[92%] ${
                  m.role === "user"
                    ? "bg-amber-400 text-slate-950 font-semibold rounded-tr-xs"
                    : "bg-slate-900 border border-slate-800 text-slate-200 rounded-tl-xs shadow-md"
                }`}
              >
                <p>{m.text}</p>

                {/* Metrics Pill Grid if available */}
                {m.metrics && (
                  <div className="mt-3 grid grid-cols-2 gap-2 pt-2 border-t border-slate-800">
                    <div className="p-2 rounded-lg bg-slate-950/60 border border-slate-800">
                      <div className="text-[9px] text-slate-400 uppercase font-bold">Open Cargo</div>
                      <div className="text-sm font-black text-amber-400">{m.metrics.active_shipments}</div>
                    </div>
                    <div className="p-2 rounded-lg bg-slate-950/60 border border-slate-800">
                      <div className="text-[9px] text-slate-400 uppercase font-bold">Active Trips</div>
                      <div className="text-sm font-black text-emerald-400">{m.metrics.active_trips}</div>
                    </div>
                    <div className="p-2 rounded-lg bg-slate-950/60 border border-slate-800">
                      <div className="text-[9px] text-slate-400 uppercase font-bold">Pending KYC</div>
                      <div className="text-sm font-black text-rose-400">{m.metrics.pending_kyc}</div>
                    </div>
                    <div className="p-2 rounded-lg bg-slate-950/60 border border-slate-800">
                      <div className="text-[9px] text-slate-400 uppercase font-bold">Support Queue</div>
                      <div className="text-sm font-black text-sky-400">{m.metrics.open_tickets}</div>
                    </div>
                  </div>
                )}

                {/* Insights Bullets */}
                {m.insights && m.insights.length > 0 && (
                  <div className="mt-2.5 pt-2 border-t border-slate-800 space-y-1">
                    {m.insights.map((ins, iIdx) => (
                      <div key={iIdx} className="flex items-start gap-1.5 text-[11px] text-amber-400/90 font-medium">
                        <ArrowRight size={12} className="shrink-0 mt-0.5 text-amber-400" />
                        <span>{ins}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ))}

          {loading && (
            <div className="flex items-center gap-2 p-3 rounded-2xl bg-slate-900 border border-slate-800 text-xs text-slate-400 max-w-[80%]">
              <Loader2 size={16} className="text-amber-400 animate-spin" />
              <span>Querying live freight database & sensors...</span>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* Suggested Quick Prompts */}
        <div className="px-4 py-2 bg-slate-900/60 border-t border-slate-800 flex items-center gap-1.5 overflow-x-auto no-scrollbar">
          {[
            "Check stale GPS signals (>30 min)",
            "Summarize pending KYC documents",
            "Review open high priority tickets",
            "Corridor matching status",
          ].map((promptText) => (
            <button
              key={promptText}
              onClick={() => handleSend(promptText)}
              disabled={loading}
              className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-[10px] font-semibold text-slate-300 border border-slate-700 whitespace-nowrap transition"
            >
              {promptText}
            </button>
          ))}
        </div>

        {/* Input Bar */}
        <div className="p-3 bg-slate-900 border-t border-slate-800">
          <form 
            onSubmit={(e) => {
              e.preventDefault();
              handleSend();
            }}
            className="flex items-center gap-2"
          >
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Ask REDO Operations AI..."
              className="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-3 py-2.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
            />
            <button
              type="submit"
              disabled={!input.trim() || loading}
              className="p-2.5 rounded-xl bg-amber-400 hover:bg-amber-500 disabled:opacity-50 text-slate-950 font-bold transition shadow-sm"
            >
              <Send size={15} />
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
