import { expect, test, type Page } from "@playwright/test";

type Violation = { directive: string; blocked: string; disposition: string };

function watchCsp(page: Page) {
  const reports: string[] = [];
  page.on("request", (request) => {
    if (new URL(request.url()).pathname === "/core/csp_reports") reports.push(request.url());
  });
  page.addInitScript(() => {
    (window as unknown as { __cspViolations: Violation[] }).__cspViolations = [];
    document.addEventListener("securitypolicyviolation", (event) => {
      (window as unknown as { __cspViolations: Violation[] }).__cspViolations.push({
        directive: event.effectiveDirective,
        blocked: event.blockedURI,
        disposition: event.disposition,
      });
    });
  });
  return reports;
}

async function violations(page: Page): Promise<Violation[]> {
  return page.evaluate(
    () => (window as unknown as { __cspViolations: Violation[] }).__cspViolations ?? [],
  );
}

test("the smoke server runs under CSP Report-Only", async ({ page }) => {
  const response = await page.goto("/en/sign_in");

  expect(response?.headers()["content-security-policy-report-only"]).toContain(
    "report-uri /core/csp_reports",
  );
  expect(response?.headers()["content-security-policy"]).toBeUndefined();
});

async function signIn(page: Page) {
  await page.goto("/en/sign_in");
  await page.getByTestId("signin.email").fill("ada@example.test");
  await page.getByTestId("signin.password").fill("secret");
  await Promise.all([page.waitForURL(/\/en\/?$/), page.getByTestId("signin.submit").click()]);
}

test("no signed-in page sends a CSP report and no violation fires", async ({ page }) => {
  const reports = watchCsp(page);
  if (process.env.E2E_SESSION_COOKIE) {
    await page.setExtraHTTPHeaders({ Cookie: process.env.E2E_SESSION_COOKIE });
  } else {
    await signIn(page);
  }

  for (const path of [
    "/en",
    "/en/example_orders/orders",
    "/en/example_orders/orders/order-1",
    "/en/example_orders/orders/order-1/edit",
    "/en/component_catalog",
  ]) {
    await page.goto(path);
    await expect(page.getByTestId("app.main")).toBeVisible();
    await page.waitForTimeout(500);

    expect(reports, path).toEqual([]);
    expect(await violations(page), path).toEqual([]);
  }
});

test("a deliberate inline script is reported (canary)", async ({ page }) => {
  const reports = watchCsp(page);
  await page.goto("/en/sign_in");

  const response = page.waitForResponse(
    (candidate) => new URL(candidate.url()).pathname === "/core/csp_reports",
  );
  await page.evaluate(() => {
    const script = document.createElement("script");
    script.textContent = "window.__csp_canary = true";
    document.head.appendChild(script);
  });

  await response;
  await expect
    .poll(async () => (await violations(page)).length, { timeout: 5_000 })
    .toBeGreaterThan(0);
  expect(reports.length).toBeGreaterThan(0);
});
