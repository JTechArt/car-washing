import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        navy: {
          50: '#eff6ff',
          600: '#1B4F72',
          700: '#154060',
          800: '#0f2f47',
        },
      },
    },
  },
  plugins: [],
}
export default config
