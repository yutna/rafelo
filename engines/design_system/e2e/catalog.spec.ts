import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

// A fixed viewport keeps the two screenshots independent of font-metric
// rounding in the bottom whitespace; the catalog still fits in one frame.
test.use({ viewport: { width: 1280, height: 1200 } });

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
  await expect(page).toHaveScreenshot("catalog.png", { fullPage: false, animations: "disabled" });
});

test("Thai catalog shows the Buddhist calendar", async ({ page }) => {
  await page.goto("/th/component_catalog");
  await expect(page.getByTestId("app-root")).toHaveAttribute("lang", "th");
  const chart = page.getByTestId("catalog-chart");
  await expect(chart).toBeVisible();
  await expect(chart).toHaveAttribute("role", "img");
  await expect(chart).toHaveAttribute("aria-label", "แผนภูมิตัวอย่าง");
  await expect(page).toHaveScreenshot("catalog-th.png", {
    fullPage: false,
    animations: "disabled",
  });
});
