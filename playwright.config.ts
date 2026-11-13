import { existsSync, readdirSync } from "node:fs";

import { defineConfig, devices } from "@playwright/test";

const sessionHeaders: Record<string, string> = {};
if (process.env.E2E_SESSION_COOKIE) {
  sessionHeaders.Cookie = process.env.E2E_SESSION_COOKIE;
}

const suites = [
  { name: "app", testDir: "e2e" },
  ...readdirSync("engines")
    .filter((engine) => existsSync(`engines/${engine}/e2e`))
    .map((engine) => ({ name: engine, testDir: `engines/${engine}/e2e` })),
];

export default defineConfig({
  fullyParallel: false,
  retries: 0,
  reporter: "list",
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL ?? "http://localhost:3000",
    testIdAttribute: "data-testid",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  expect: {
    toHaveScreenshot: { maxDiffPixelRatio: 0.02, animations: "disabled" },
  },
  projects: suites.map((suite) => ({
    ...suite,
    use: {
      ...devices["Desktop Chrome"],
      ...(suite.name === "design_system" ? { extraHTTPHeaders: sessionHeaders } : {}),
    },
  })),
  webServer: process.env.PLAYWRIGHT_BASE_URL
    ? undefined
    : {
        command: "bin/dev",
        url: "http://localhost:3000/en/component_catalog",
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
      },
});
