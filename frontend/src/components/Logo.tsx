export default function Logo({ compact }: { compact?: boolean }) {
  return (
    <span className="inline-flex items-center gap-2 select-none">
      {/* Brand mark: yellow-black R chevron */}
      <svg width="30" height="30" viewBox="0 0 32 32" aria-hidden="true">
        <path d="M4 26 L14 6 h8 l-6 12 h6 l-8 8 z" fill="#111417" />
        <path d="M12 26 L22 6 h6 l-10 20 z" fill="#F7B500" />
      </svg>
      {!compact && (
        <span className="leading-none">
          <span className="block text-xl font-extrabold tracking-tight text-ink">redo</span>
          <span className="block text-[10px] font-semibold text-ink-faint tracking-wide">Transport &amp; Logistics</span>
        </span>
      )}
    </span>
  );
}
