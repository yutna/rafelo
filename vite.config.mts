import inertia from "@inertiajs/vite";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import ruby from "vite-plugin-ruby";

export default defineConfig({
  plugins: [ruby(), inertia({ ssr: false }), tailwindcss(), react()],
  build: {
    assetsInlineLimit: 0,
  },
  server: {
    host: "0.0.0.0",
  },
});
