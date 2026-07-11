/** @type {import('tailwindcss').Config} */
// ===== Modern Teal + Slate theme =====
// brand  = Teal  #0E7C7B (primary actions, nav, headers)
// slate  = neutral surfaces/text (Tailwind default slate, referenced explicitly)
// status = acknowledgement colour coding (thesis §4.8):
//          unread = red | read = amber | acknowledged = green
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#e6f3f3",
          100: "#c0e0df",
          200: "#8fc9c8",
          300: "#56adac",
          400: "#2c9594",
          500: "#0e7c7b", // primary
          600: "#0b6968",
          700: "#095353",
          800: "#073f3f",
          900: "#042a2a",
        },
        ink: {
          DEFAULT: "#334155", // slate-700 — primary text
          muted: "#64748b", // slate-500
          line: "#e2e8f0", // slate-200 — borders
          surface: "#f8fafc", // slate-50 — page background
        },
        status: {
          unread: "#dc2626", // red-600
          read: "#d97706", // amber-600
          ack: "#16a34a", // green-600
        },
      },
      fontFamily: {
        sans: ['"Segoe UI"', "system-ui", "-apple-system", "Roboto", "Helvetica", "Arial", "sans-serif"],
      },
      boxShadow: {
        card: "0 1px 2px rgba(15, 23, 42, 0.04), 0 4px 16px rgba(15, 23, 42, 0.06)",
        lift: "0 10px 30px rgba(15, 23, 42, 0.10)",
      },
      backgroundImage: {
        "brand-gradient": "linear-gradient(165deg, #0e7c7b 0%, #084f4e 55%, #063a3a 100%)",
      },
    },
  },
  plugins: [],
};
