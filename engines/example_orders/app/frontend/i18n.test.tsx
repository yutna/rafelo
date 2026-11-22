import i18next from "i18next";
import { describe, expect, it } from "vitest";

import { useOrdersTranslation } from "./i18n";

describe("example_orders i18n", () => {
  it("reads its copy from the engine namespace", async () => {
    await i18next.init({
      lng: "th",
      resources: { th: { example_orders: { orders: { title: "คำสั่งซื้อ" } } } },
    });

    const t = useOrdersTranslation();

    expect(t("orders.title")).toBe("คำสั่งซื้อ");
  });
});
