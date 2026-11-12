import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

export default defineConfig({
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
