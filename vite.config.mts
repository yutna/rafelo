import inertia from "@inertiajs/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";
import ruby from "vite-plugin-ruby";

import { engineAliases, engineFsAllow } from "./config/frontend_aliases.mts";
import { reactPlugins } from "./config/frontend_react.mts";

export default defineConfig({
  plugins: [ruby(), inertia({ ssr: false }), tailwindcss(), ...reactPlugins()],
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
