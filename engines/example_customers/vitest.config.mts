import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";
import { fileURLToPath } from "node:url";
import { engineAliases } from "../../config/frontend_aliases.mts";

const setupFiles = [fileURLToPath(new URL("../../vitest.setup.ts", import.meta.url))];

export default defineConfig({
  plugins: [react()],
  resolve: { alias: engineAliases },
  test: {
    projects: [
      {
        test: {
          name: "example_customers",
          environment: "jsdom",
          include: ["app/frontend/**/*.test.tsx", "app/frontend/**/hooks/**/*.test.ts"],
          setupFiles,
        },
      },
      {
        test: {
          name: "example_customers:node",
          environment: "node",
          include: ["app/frontend/**/*.test.ts"],
          exclude: ["app/frontend/**/hooks/**"],
        },
      },
    ],
  },
});
