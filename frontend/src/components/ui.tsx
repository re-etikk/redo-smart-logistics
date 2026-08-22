import { createContext, useCallback, useContext, useState, type ReactNode, type ButtonHTMLAttributes, type HTMLAttributes } from "react";
import { CheckCircle2, AlertCircle, ShieldCheck, Star, Sparkles, X, ChevronRight } from "lucide-react";

type Tone = "neutral" | "ok" | "warn" | "danger" | "accent";

export function Button({ variant = "primary", className = "", children, ...props }:
  ButtonHTMLAttributes<HTMLButtonElement> & { variant?: "primary" | "secondary" | "ghost" | "danger" }) {
  const styles = {
    primary: "bg-blue-600 text-white hover:bg-blue-700 active:scale-[.99] shadow-sm shadow-blue-500/20",
    secondary: "bg-white text-slate-800 border border-slate-200 hover:border-slate-300 hover:bg-slate-50 shadow-xs",
    ghost: "text-slate-600 hover:bg-slate-100 hover:text-slate-900",
    danger: "bg-rose-600 text-white hover:bg-rose-700 shadow-xs",
  };
  return (
    <button
      className={`inline-flex items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold
        transition-all duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2
        disabled:opacity-50 disabled:pointer-events-none ${styles[variant]} ${className}`}
      {...props}
    >{children}</button>
  );
}

export function Badge({ tone = "neutral", children, className = "" }: { tone?: Tone; children: ReactNode; className?: string }) {
  const tones: Record<Tone, string> = {
    neutral: "bg-slate-100 text-slate-700 border border-slate-200/80",
    ok: "bg-emerald-50 text-emerald-700 border border-emerald-200/80",
    warn: "bg-amber-50 text-amber-700 border border-amber-200/80",
    danger: "bg-rose-50 text-rose-700 border border-rose-200/80",
    accent: "bg-blue-50 text-blue-700 border border-blue-200/80",
  };
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ${tones[tone]} ${className}`}>
      {children}
    </span>
  );
}

export function VerifiedBadge({ demo }: { demo?: boolean }) {
  return (
    <Badge tone="ok">
      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
      {demo ? "Demo Verified" : "Verified Partner"}
    </Badge>
  );
}

export function MatchScore({ score }: { score: number }) {
  const pct = Math.round(score * 100);
  const tone = pct >= 85 ? "text-emerald-600 bg-emerald-50 border-emerald-200" : pct >= 60 ? "text-blue-600 bg-blue-50 border-blue-200" : "text-slate-600 bg-slate-50 border-slate-200";
  return (
    <div className="flex items-center gap-2">
      <div className={`px-2.5 py-1 rounded-lg border text-sm font-bold tabular-nums flex items-center gap-1 ${tone}`}>
        <Sparkles className="w-3.5 h-3.5" />
        <span>{pct}%</span>
      </div>
      <div className="text-[11px] font-semibold text-slate-500 uppercase tracking-wide">Match</div>
    </div>
  );
}

export const statusTone = (s: string): Tone =>
  s === "completed" || s === "delivered" || s === "confirmed" ? "ok"
  : s === "cancelled" || s === "disputed" ? "danger"
  : s === "pending" ? "warn" : "accent";

export const statusLabel = (s: string) => s.replaceAll("_", " ").replace(/^\w/, (c) => c.toUpperCase());

export function CapacityGauge({ total, used, label }: { total: number; used: number; label?: string }) {
  const pct = Math.min(100, Math.round((used / total) * 100));
  return (
    <div className="space-y-1.5">
      {label && (
        <div className="flex justify-between text-xs font-semibold text-slate-600">
          <span>{label}</span>
          <span className="tabular-nums">{used} / {total} Tonnes ({pct}%)</span>
        </div>
      )}
      <div className="h-3 rounded-full bg-slate-100 border border-slate-200/80 overflow-hidden p-0.5" role="progressbar"
        aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} aria-label={label || "capacity used"}>
        <div className={`h-full rounded-full transition-all duration-500 ${pct > 80 ? "bg-amber-500" : "bg-blue-600"}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

export function Card({ className = "", hover, children, ...props }: {
  className?: string; hover?: boolean; children: ReactNode;
} & HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={`bg-white rounded-2xl border border-slate-200/80 shadow-card ${hover ? "transition-all duration-200 hover:shadow-lift hover:-translate-y-0.5 hover:border-slate-300" : ""} ${className}`} {...props}>
      {children}
    </div>
  );
}

export function StatTile({ title, value, subtext, icon, trend }: {
  title: string; value: string | number; subtext?: string; icon?: ReactNode; trend?: string;
}) {
  return (
    <Card className="p-5 relative overflow-hidden">
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold text-slate-500 tracking-wide uppercase">{title}</span>
        {icon && <div className="p-2 rounded-xl bg-blue-50 text-blue-600">{icon}</div>}
      </div>
      <div className="mt-2 flex items-baseline gap-2">
        <span className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">{value}</span>
        {trend && <span className="text-xs font-bold text-emerald-600">{trend}</span>}
      </div>
      {subtext && <p className="mt-1 text-xs text-slate-500 font-medium">{subtext}</p>}
    </Card>
  );
}

export function Skeleton({ className = "" }: { className?: string }) {
  return <div className={`animate-pulse rounded-xl bg-slate-200/80 ${className}`} aria-hidden="true" />;
}

export function CardSkeleton() {
  return (
    <Card className="p-5 space-y-3">
      <Skeleton className="h-4 w-2/5" /><Skeleton className="h-3 w-4/5" />
      <Skeleton className="h-3 w-3/5" /><Skeleton className="h-9 w-32" />
    </Card>
  );
}

export function EmptyState({ title, hint, action }: { title: string; hint?: string; action?: ReactNode }) {
  return (
    <Card className="p-10 text-center space-y-3 max-w-md mx-auto my-6">
      <div className="w-12 h-12 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center mx-auto text-slate-400">
        <AlertCircle className="w-6 h-6" />
      </div>
      <p className="font-bold text-slate-900 text-base">{title}</p>
      {hint && <p className="text-xs text-slate-500 leading-relaxed">{hint}</p>}
      {action && <div className="pt-2">{action}</div>}
    </Card>
  );
}

export function ErrorState({ message, onRetry, cta = "Try again" }: { message: string; onRetry: () => void; cta?: string }) {
  return (
    <Card className="p-8 text-center space-y-3 max-w-md mx-auto">
      <div className="w-10 h-10 rounded-full bg-rose-50 border border-rose-200 flex items-center justify-center mx-auto text-rose-600">
        <AlertCircle className="w-5 h-5" />
      </div>
      <p className="font-semibold text-slate-900">{message}</p>
      <div className="pt-2"><Button variant="secondary" onClick={onRetry}>{cta}</Button></div>
    </Card>
  );
}

const ToastCtx = createContext<(msg: string, tone?: "ok" | "danger" | "warn") => void>(() => {});
export const useToast = () => useContext(ToastCtx);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<{ id: number; msg: string; tone: string }[]>([]);
  const push = useCallback((msg: string, tone: "ok" | "danger" | "warn" = "ok") => {
    const id = Date.now() + Math.random();
    setToasts((t) => [...t, { id, msg, tone }]);
    setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 3500);
  }, []);
  return (
    <ToastCtx.Provider value={push}>
      {children}
      <div className="fixed bottom-20 md:bottom-6 right-6 z-50 space-y-2.5 w-[92%] max-w-sm pointer-events-none" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`pointer-events-auto rounded-xl p-3.5 text-xs font-semibold text-white shadow-lift flex items-center gap-2.5 transition-all animate-in fade-in slide-in-from-bottom-2
            ${t.tone === "danger" ? "bg-rose-600" : t.tone === "warn" ? "bg-amber-600" : "bg-slate-900"}`}>
            {t.tone === "danger" ? <AlertCircle className="w-4 h-4 text-white flex-shrink-0" /> : <CheckCircle2 className="w-4 h-4 text-emerald-400 flex-shrink-0" />}
            <span className="flex-1">{t.msg}</span>
          </div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

export function Rating({ value }: { value: number }) {
  return (
    <span className="inline-flex items-center gap-1 text-xs font-bold text-slate-800 bg-amber-50 border border-amber-200/80 px-2 py-0.5 rounded-md">
      <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
      {value.toFixed(1)}
    </span>
  );
}

export function ReasonChips({ reasons }: { reasons: string[] }) {
  return (
    <div className="flex flex-wrap gap-1.5">
      {reasons.map((r) => (
        <span key={r} className="rounded-md bg-blue-50 text-blue-700 border border-blue-200/60 px-2 py-0.5 text-[11px] font-semibold flex items-center gap-1">
          <Sparkles className="w-3 h-3 text-blue-500" />
          {r}
        </span>
      ))}
    </div>
  );
}

export function Field({ label, children, error }: { label: string; children: ReactNode; error?: string }) {
  return (
    <label className="block text-xs font-semibold text-slate-700">
      {label}
      <div className="mt-1.5">{children}</div>
      {error && <p className="mt-1 text-xs font-medium text-rose-600 flex items-center gap-1"><AlertCircle className="w-3 h-3" />{error}</p>}
    </label>
  );
}

export const inputCls =
  "w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm bg-white text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition disabled:opacity-50 disabled:bg-slate-50";

