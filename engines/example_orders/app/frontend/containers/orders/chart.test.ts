import { describe, expect, it } from "vitest";

import { ordersChartOption } from "./chart";

describe("ordersChartOption", () => {
  it("passes the server series through as the chart option", () => {
    const series = [
      {
        name: "Orders",
        type: "pie" as const,
        data: [{ label: "Open", value: 3 }],
      },
    ];

    expect(ordersChartOption({ series })).toEqual({ series });
  });
});
