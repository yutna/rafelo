import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

import { engineAliases } from "./config/frontend_aliases.mts";

export default defineConfig({
  resolve: { alias: engineAliases },
  test: {
    projects: [
      {
        plugins: [react()],
        test: {
          name: "app",
          environment: "jsdom",
          include: [
            "app/frontend/**/*.test.tsx",
            "app/frontend/**/hooks/**/*.test.ts",
          ],
          setupFiles: ["./vitest.setup.ts"],
        },
      },
      {
        plugins: [react()],
        test: {
          name: "engines",
          environment: "jsdom",
          include: ["engines/*/app/frontend/**/*.test.ts", "engines/*/app/frontend/**/*.test.tsx"],
          exclude: ["engines/*/spec/**"],
          setupFiles: ["./vitest.setup.ts"],
        },
      },
      {
        test: {
          name: "app:node",
          environment: "node",
          include: ["app/frontend/**/*.test.ts"],
          exclude: ["app/frontend/**/hooks/**/*.test.ts"],
        },
      },
    ],
  },
});
