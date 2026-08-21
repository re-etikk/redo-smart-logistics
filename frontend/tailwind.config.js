/** Redo design tokens — restrained logistics palette. Semantic colors keep meaning. */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        ink: { DEFAULT: '#16212D', soft: '#3B4754', faint: '#69747F' },
        canvas: '#F5F6F8',
        line: '#E4E7EB',
        accent: { DEFAULT: '#2952E3', soft: '#EAF0FF' },
        ok: { DEFAULT: '#12805C', soft: '#E8F5EF' },
        warn: { DEFAULT: '#B45309', soft: '#FDF3E7' },
        danger: { DEFAULT: '#C2362B', soft: '#FCEEEC' }
      },
      fontFamily: { sans: ['Inter', 'system-ui', 'sans-serif'] },
      boxShadow: {
        card: '0 1px 2px rgba(22,33,45,.06), 0 4px 12px rgba(22,33,45,.05)',
        lift: '0 2px 4px rgba(22,33,45,.08), 0 10px 24px rgba(22,33,45,.10)'
      }
    }
  },
  plugins: []
}
