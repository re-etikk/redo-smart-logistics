export default function Logo({ compact, className = "" }: { compact?: boolean; className?: string }) {
  return (
    <span className={`inline-flex items-center select-none ${className}`}>
      <img
        src="/assets/redo_logo.jpg"
        alt="REDO Transport & Logistics"
        className={`${compact ? "h-8 w-auto" : "h-9 sm:h-10 w-auto"} object-contain rounded-lg dark:bg-white dark:px-1 dark:py-0.5 transition-all`}
      />
    </span>
  );
}
