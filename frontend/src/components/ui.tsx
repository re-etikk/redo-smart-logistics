import { createContext, useCallback, useContext, useState, type ReactNode, type ButtonHTMLAttributes, type HTMLAttributes } from "react";

type Tone = "neutral" | "ok" | "warn" | "danger" | "accent";

export function Button({ variant = "primary", className = "", children, ...props }:
  ButtonHTMLAttributes<HTMLButtonElement> & { variant?: "primary" | "secondary" | "ghost" | "danger" }) {
  const styles = {
    primary: "bg-accent text-white hover:bg-[#1F44C4] active:scale-[.99]",
    secondary: "bg-white text-ink border border-line hover:border-ink/30",
    ghost: "text-ink-soft hover:bg-ink/5",
    danger: "bg-danger text-white hover:brightness-95",
  };
  return (
    <button
      className={`inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2.5 text-sm font-semibold
        transition focus:outline-none focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2
        disabled:opacity-50 disabled:pointer-events-none ${styles[variant]} ${className}`}
      {...props}
    >{children}</button>
  );
}

export function Badge({ tone = "neutral", children }: { tone?: Tone; children: ReactNode }) {
  const tones: Record<Tone, string> = {
    neutral: "bg-ink/5 text-ink-soft", ok: "bg-ok-soft text-ok",
    warn: "bg-warn-soft text-warn", danger: "bg-danger-soft text-danger",
    accent: "bg-accent-soft text-accent",
  };
  return <span className={`inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-semibold ${tones[tone]}`}>{children}</span>;
}

export function VerifiedBadge({ demo }: { demo?: boolean }) {
  return (
    <Badge tone="ok">
      <svg width="11" height="11" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path d="M20 6L9 17l-5-5" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
      {demo ? "Demo verified" : "Verified"}
    </Badge>
  );
}

export function MatchScore({ score }: { score: number }) {
  const pct = Math.round(score * 100);
  const tone = pct >= 85 ? "text-ok" : pct >= 60 ? "text-accent" : "text-ink-faint";
  return (
    <div className="text-right">
      <div className={`text-2xl font-bold leading-none tabular-nums ${tone}`}>{pct}%</div>
      <div className="text-[11px] font-medium text-ink-faint mt-0.5">match</div>
    </div>
  );
}

export const statusTone = (s: string): Tone =>
  s === "completed" || s === "delivered" ? "ok"
  : s === "cancelled" || s === "disputed" ? "danger"
  : s === "pending" ? "warn" : "accent";

export const statusLabel = (s: string) => s.replaceAll("_", " ").replace(/^\w/, (c) => c.toUpperCase());

export function CapacityGauge({ total, used, label }: { total: number; used: number; label?: string }) {
  const pct = Math.min(100, Math.round((used / total) * 100));
  return (
    <div>
      {label && (
        <div className="flex justify-between text-xs font-medium text-ink-faint mb-1">
          <span>{label}</span>
          <span className="tabular-nums">{used} / {total} T · {pct}%</span>
        </div>
      )}
      <div className="h-2.5 rounded-full bg-ink/10 overflow-hidden" role="progressbar"
        aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} aria-label={label || "capacity used"}>
        <div className="h-full rounded-full bg-accent transition-all duration-500" style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

export function Card({ className = "", hover, children, ...props }: {
  className?: string; hover?: boolean; children: ReactNode;
} & HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={`bg-white rounded-xl border border-line shadow-card ${hover ? "transition hover:shadow-lift hover:-translate-y-px" : ""} ${className}`} {...props}>
      {children}
    </div>
  );
}

export function Skeleton({ className = "" }: { className?: string }) {
  return <div className={`animate-pulse rounded-lg bg-ink/10 ${className}`} aria-hidden="true" />;
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
    <Card className="p-10 text-center">
      <p className="font-semibold text-ink">{title}</p>
      {hint && <p className="text-sm text-ink-faint mt-1">{hint}</p>}
      {action && <div className="mt-4">{action}</div>}
    </Card>
  );
}

export function ErrorState({ message, onRetry, cta = "Try again" }: { message: string; onRetry: () => void; cta?: string }) {
  return (
    <Card className="p-8 text-center">
      <p className="font-semibold text-ink">{message}</p>
      <div className="mt-4"><Button variant="secondary" onClick={onRetry}>{cta}</Button></div>
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
      <div className="fixed bottom-20 md:bottom-6 left-1/2 -translate-x-1/2 z-50 space-y-2 w-[92%] max-w-sm" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`rounded-lg px-4 py-3 text-sm font-medium text-white shadow-lift
            ${t.tone === "danger" ? "bg-danger" : t.tone === "warn" ? "bg-warn" : "bg-ink"}`}>{t.msg}</div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

export function Rating({ value }: { value: number }) {
  return (
    <span className="inline-flex items-center gap-1 text-sm font-semibold text-ink">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="#B45309" aria-hidden="true">
        <path d="M12 2l2.9 6.3 6.9.8-5.1 4.7 1.4 6.8L12 17.3 5.9 20.6l1.4-6.8L2.2 9.1l6.9-.8L12 2z" />
      </svg>
      {value.toFixed(1)}
    </span>
  );
}

export function ReasonChips({ reasons }: { reasons: string[] }) {
  return (
    <div className="flex flex-wrap gap-1.5">
      {reasons.map((r) => (
        <span key={r} className="rounded-md bg-accent-soft text-accent px-2 py-0.5 text-[11px] font-semibold">{r}</span>
      ))}
    </div>
  );
}

export function Field({ label, children, error }: { label: string; children: ReactNode; error?: string }) {
  return (
    <label className="block text-sm font-semibold text-ink">
      {label}
      <div className="mt-1.5">{children}</div>
      {error && <p className="mt-1 text-xs font-medium text-danger">{error}</p>}
    </label>
  );
}

export const inputCls =
  "w-full rounded-lg border border-line px-3 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-accent disabled:opacity-50";
