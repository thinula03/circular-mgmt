import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Dev server on 5173 (matches FRONTEND_ORIGIN in backend CORS config).
// /api is proxied to the Flask backend on :5000 so the app can call it
// without CORS friction during development.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://127.0.0.1:5000",
        changeOrigin: true,
      },
    },
  },
});
