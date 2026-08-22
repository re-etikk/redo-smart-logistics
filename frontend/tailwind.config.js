/** Redo design tokens — Enterprise Logistics Platform Palette */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        ink: { DEFAULT: '#0F172A', soft: '#334155', faint: '#64748B' },
        canvas: '#F8FAFC',
        line: '#E2E8F0',
        accent: { DEFAULT: '#2563EB', hover: '#1D4ED8', soft: '#EFF6FF' },
        ok: { DEFAULT: '#059669', soft: '#ECFDF5' },
        warn: { DEFAULT: '#D97706', soft: '#FFFBEB' },
        danger: { DEFAULT: '#E11D48', soft: '#FFF1F2' }
      },
      fontFamily: { sans: ['Inter', 'Plus Jakarta Sans', 'system-ui', 'sans-serif'] },
      boxShadow: {
        card: '0 1px 3px 0 rgba(15, 23, 42, 0.05), 0 4px 16px -2px rgba(15, 23, 42, 0.04)',
        lift: '0 10px 30px -5px rgba(15, 23, 42, 0.08), 0 4px 12px -2px rgba(15, 23, 42, 0.04)',
        glow: '0 0 20px -3px rgba(37, 99, 235, 0.35)'
      }
    }
  },
  plugins: []
}

