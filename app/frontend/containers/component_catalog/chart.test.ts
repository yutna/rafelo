import { describe, expect, it } from "vitest";

import { catalogChartOption } from "./chart";

describe("catalogChartOption", () => {
  it("builds the catalog chart option without the DOM", () => {
    expect(catalogChartOption("Sample")).toEqual({
      series: [
        {
          name: "Sample",
          type: "pie",
          data: [
            { label: "A", value: 1 },
            { label: "B", value: 2 },
          ],
        },
      ],
    });
  });
});
