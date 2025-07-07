/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#00684a',
          foreground: '#ffffff',
        },
        secondary: {
          DEFAULT: '#b1ff08',
          foreground: '#000000',
        },
      },
    },
  },
  plugins: [],
}