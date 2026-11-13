import { expect, test } from "@playwright/test";

const upstream = process.env.E2E_UPSTREAM_URL ?? "http://127.0.0.1:4100";

function pageProps(html: string): { props: { meta: { formToken: string } } } {
  const match = html.match(/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/s);
  if (!match) throw new Error("the page did not render its Inertia props");
  return JSON.parse(match[1]);
}

test.describe("example_orders", () => {
  test.beforeEach(async ({ request }) => {
    expect((await request.post(`${upstream}/__reset`)).ok()).toBe(true);
    expect((await request.post(`${upstream}/__conflict`)).ok()).toBe(true);
  });

  test("signs in, lists, shows and recovers from a conflicting edit", async ({ page }) => {
    await page.goto("/en/sign_in");
    await page.getByTestId("signin.email").fill("ada@example.test");
    await page.getByTestId("signin.password").fill("secret");
    await Promise.all([
      page.waitForURL(/\/en\/?$/),
      page.getByTestId("signin.submit").click(),
    ]);

    await page.goto("/en/example_orders/orders");
    await expect(page.getByTestId("example_orders.orders.index.list")).toBeVisible();
    await expect(page.getByTestId("example_orders.orders.index.chart")).toBeVisible();
    await expect(page.getByTestId("example_orders.orders.index.row.order-1")).toBeVisible();

    await page.getByTestId("example_orders.orders.index.row.order-1").click();
    await expect(page.getByTestId("example_orders.orders.show.page")).toBeVisible();
    await expect(page.getByTestId("example_orders.orders.show.status")).toHaveText("open");

    await page.getByTestId("example_orders.orders.show.edit").click();
    await expect(page.getByTestId("example_orders.orders.form.status")).toHaveValue("open");
    await page.reload();
    await expect(page.getByTestId("example_orders.orders.form.status")).toHaveValue("open");

    const formToken = pageProps(await page.content()).props.meta.formToken;
    expect(formToken).toBeTruthy();

    await page.getByTestId("example_orders.orders.form.status").fill("paid");
    const patchRequest = page.waitForRequest(
      (request) => request.method() === "PATCH" && request.url().includes("/en/example_orders/orders/order-1"),
    );
    await page.getByTestId("example_orders.orders.edit.submit").click();
    const sent = (await patchRequest).postDataJSON();
    expect(sent.token).toBe(formToken);
    expect(sent.version).toBe(1);

    await expect(page.getByTestId("example_orders.orders.form.base-error")).toHaveText(
      "The order changed since you opened it.",
    );
    await expect(page.getByTestId("example_orders.orders.form.status")).toHaveValue("paid");

    await page.getByTestId("example_orders.orders.edit.submit").click();
    await expect(page.getByTestId("example_orders.orders.show.page")).toBeVisible();
    await expect(page.getByTestId("example_orders.orders.show.status")).toHaveText("paid");
  });
});
