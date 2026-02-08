import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // K8s-inspired color palette
        'k8s-blue': '#326CE5',
        'k8s-dark': '#1a1a2e',
        'terminal-green': '#00ff00',
        'terminal-amber': '#ffb000',
      },
    },
  },
  // Note: line-clamp is built into Tailwind v3.3+, but we include
  // the plugin explicitly for clarity and backwards compatibility
  plugins: [require('@tailwindcss/line-clamp')],
}

export default config
