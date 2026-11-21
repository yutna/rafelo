import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

// A fixed viewport keeps the two screenshots independent of font-metric
// rounding in the bottom whitespace; the catalog still fits in one frame.
const CATALOG_VIEWPORT = { width: 1280, height: 1750 };
test.use({ viewport: CATALOG_VIEWPORT });

async function expectCatalogFits(page: import("@playwright/test").Page) {
  const { bottom, width } = await page.getByTestId("app.main").evaluate((main) => ({
    bottom: main.firstElementChild?.getBoundingClientRect().bottom ?? 0,
    width: document.documentElement.scrollWidth,
  }));
  expect(bottom).toBeLessThanOrEqual(CATALOG_VIEWPORT.height);
  expect(width).toBeLessThanOrEqual(CATALOG_VIEWPORT.width);
}

test("catalog has no serious axe violations", async ({ page }) => {
  await page.goto("/en/component_catalog");
  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
    .analyze();

  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
});

test("catalog screenshot matches its committed baseline", async ({ page }) => {
  await page.goto("/en/component_catalog");
  await expect(page.getByTestId("catalog-button")).toBeVisible();
  await expect(page.getByTestId("catalog-chart")).toBeVisible();
  await expect(page.getByTestId("catalog-empty")).toBeVisible();
  await expectCatalogFits(page);
  await expect(page).toHaveScreenshot("catalog.png", { fullPage: false, animations: "disabled" });
});

test("Thai catalog shows the Buddhist calendar", async ({ page }) => {
  await page.goto("/th/component_catalog");
  await expect(page.getByTestId("app-root")).toHaveAttribute("lang", "th");
  const chart = page.getByTestId("catalog-chart");
  await expect(chart).toBeVisible();
  await expect(chart).toHaveAttribute("role", "img");
  await expect(chart).toHaveAttribute("aria-label", /./);
  await expect(chart).not.toHaveAttribute("aria-hidden");
  await expect(page.getByTestId("catalog-empty")).toBeVisible();
  await expectCatalogFits(page);
  await expect(page).toHaveScreenshot("catalog-th.png", {
    fullPage: false,
    animations: "disabled",
  });
});
