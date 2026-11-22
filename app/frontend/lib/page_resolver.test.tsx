import { describe, expect, it } from "vitest";

import { resolvePage } from "./page_resolver";

const page = {
  props: {
    app: { locale: "en" },
    trace: { requestId: "request-1", traceId: "trace-1" },
  },
};

describe("resolvePage", () => {
  it("resolves one page name to one component identity", async () => {
    const first = await resolvePage("errors/show", page);
    const second = await resolvePage("errors/show", page);

    expect(first).toBe(second);
  });

  it("rejects a page name it does not know", async () => {
    await expect(resolvePage("missing/page", page)).rejects.toThrow("Page not found: missing/page");
  });

  it("wraps an app page and an engine page in a named layout", async () => {
    const appPage = await resolvePage("home/index", page);
    const enginePage = await resolvePage("example_orders/orders/index", page);

    expect(typeof appPage.layout).toBe("function");
    expect(typeof enginePage.layout).toBe("function");
  });
});
