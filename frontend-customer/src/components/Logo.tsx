export default function Logo({ compact }: { compact?: boolean }) {
  return (
    <span className="inline-flex items-center gap-2.5 select-none">
      {/* Brand mark: responsive R mark with yellow accent slash */}
      <svg width="36" height="36" viewBox="0 0 44 44" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <path d="M6 36 L18 8 H28 C34 8 38 12 36 18 C34 23 29 25 24 25 L32 36 H24 L17 25 H14 L9 36 H6 Z" className="fill-slate-900 dark:fill-white transition-colors" />
        <path d="M15 12 L19 4 H25 L21 12 H15 Z" fill="#FFC800" />
      </svg>
      {!compact && (
        <span className="leading-none">
          <span className="block text-2xl font-black tracking-tight text-slate-950 dark:text-white transition-colors">
            redo
          </span>
          <span className="block text-[9px] font-extrabold text-slate-500 dark:text-slate-400 tracking-wider uppercase mt-0.5 transition-colors">
            Transport &amp; Logistics
          </span>
        </span>
      )}
    </span>
  );
}
