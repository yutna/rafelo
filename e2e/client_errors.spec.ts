import { expect, test } from "@playwright/test";

test("a report sent after sign-in is accepted without viewer data", async ({ page }) => {
  await page.goto("/en/sign_in");
  await page.getByTestId("signin.email").fill("ada@example.test");
  await page.getByTestId("signin.password").fill("secret");
  await Promise.all([
    page.waitForURL(/\/en\/?$/),
    page.getByTestId("signin.submit").click(),
  ]);

  const response = page.waitForResponse(
    (candidate) => candidate.url().endsWith("/core/client_errors") && candidate.request().method() === "POST",
  );
  await page.evaluate(() => {
    window.dispatchEvent(new ErrorEvent("error", { error: new Error("browser client report") }));
  });
  const report = await response;

  expect(report.status()).toBe(204);
  expect(await report.text()).toBe("");
  expect(report.request().postDataJSON().message).toBe("browser client report");
  expect(report.request().headers()["x-csrf-token"]).toBeTruthy();
});
