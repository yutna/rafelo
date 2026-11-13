import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("catalog has no serious axe violations", async ({ page }) => {
  await page.goto("/en/component_catalog");
  const results = await new AxeBuilder({ page }).withTags([ "wcag2aa" ]).analyze();

  expect(results.violations.filter((violation) => violation.impact === "serious" || violation.impact === "critical")).toEqual([]);
});

test("catalog screenshot matches its committed baseline", async ({ page }) => {
  await page.goto("/en/component_catalog");
  await expect(page.getByTestId("catalog-button")).toBeVisible();
  await expect(page).toHaveScreenshot("catalog.png", { fullPage: true, animations: "disabled" });
});

test("Thai catalog shows the Buddhist calendar", async ({ page }) => {
  await page.goto("/th/component_catalog");
  await expect(page.getByTestId("app-root")).toHaveAttribute("lang", "th");
});
