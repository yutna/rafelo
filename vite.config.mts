import inertia from "@inertiajs/vite";
import tailwindcss from "@tailwindcss/vite";
import babel from "@rolldown/plugin-babel";
import react, { reactCompilerPreset } from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import ruby from "vite-plugin-ruby";

import { engineAliases, engineFsAllow } from "./config/frontend_aliases.mts";

export default defineConfig({
  plugins: [ruby(), inertia({ ssr: false }), tailwindcss(), react(), babel({ presets: [reactCompilerPreset()] })],
  build: {
    assetsInlineLimit: 0,
  },
  resolve: {
    alias: engineAliases,
  },
  server: {
    fs: {
      allow: engineFsAllow,
    },
    host: "0.0.0.0",
  },
});
