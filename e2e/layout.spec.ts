import { expect, test, type Page } from "@playwright/test";

async function expectMainContentLinkMovesFocus(page: Page) {
  await page.bringToFront();
  await expect(page.getByTestId("app.main")).toBeVisible();
  await page.evaluate(() => {
    (document.activeElement as HTMLElement | null)?.blur();
  });
  await page.keyboard.press("Tab");
  const link = page.getByTestId("app.main-link");
  await expect(link).toBeFocused();

  await page.keyboard.press("Enter");
  await expect(page.getByTestId("app.main")).toBeFocused();
}

test("the main-content link moves focus into the main landmark in every shell", async ({
  page,
}) => {
  await page.goto("/en/sign_in");
  await expectMainContentLinkMovesFocus(page);

  await page.getByTestId("signin.email").fill("ada@example.test");
  await page.getByTestId("signin.password").fill("secret");
  await Promise.all([page.waitForURL(/\/en\/?$/), page.getByTestId("signin.submit").click()]);

  await page.goto("/en");
  await expect(page.getByTestId("app.main")).toBeVisible();
  await expectMainContentLinkMovesFocus(page);

  const response = await page.goto("/en/example_orders/orders/unknown");
  expect(response?.status()).toBe(404);
  await expect(page.getByTestId("app.main")).toBeVisible();
  await expectMainContentLinkMovesFocus(page);
});
