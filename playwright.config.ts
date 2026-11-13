import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "engines/design_system/e2e",
  fullyParallel: false,
  retries: 0,
  reporter: "list",
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL ?? "http://localhost:3000",
    extraHTTPHeaders: process.env.E2E_SESSION_COOKIE
      ? { Cookie: process.env.E2E_SESSION_COOKIE }
      : {},
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  expect: {
    toHaveScreenshot: { maxDiffPixelRatio: 0.02, animations: "disabled" },
  },
  projects: [{ name: "design_system", use: { ...devices["Desktop Chrome"] } }],
  webServer: process.env.PLAYWRIGHT_BASE_URL
    ? undefined
    : {
        command: "bin/dev",
        url: "http://localhost:3000/en/component_catalog",
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
      },
});
