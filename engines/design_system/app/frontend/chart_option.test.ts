import { describe, expect, it } from "vitest";

import type { ChartSeries } from "./chart.types";

import { buildChartOption, chartHoverText, chartTableRows } from "./chart_option";

const context = { locale: "en", timeZone: "UTC", description: "Orders by status" };

const pie: ChartSeries[] = [
  {
    name: "Orders",
    type: "pie",
    data: [
      { label: "Open", value: 1200 },
      { label: "Paid", value: 300 },
    ],
  },
];

describe("buildChartOption", () => {
  it("builds a pie option with aria, labels and formatted values", () => {
    const option = buildChartOption(pie, context) as {
      aria: { enabled: boolean; label: { description: string } };
      series: {
        type: string;
        data: { name: string; value: number }[];
        label: { formatter: (params: { name: string; value: number }) => string };
      }[];
    };

    expect(option.aria).toEqual({
      enabled: true,
      label: { description: "Orders by status" },
    });
    expect(option.series[0]?.type).toBe("pie");
    expect(option.series[0]?.data).toEqual([
      { name: "Open", value: 1200 },
      { name: "Paid", value: 300 },
    ]);
    expect(option.series[0]?.label.formatter({ name: "Open", value: 1200 })).toBe("Open: 1,200");
  });
});

describe("chartHoverText", () => {
  it("formats the hovered point with the locale and its date", () => {
    const series: ChartSeries[] = [
      {
        name: "Revenue",
        type: "pie",
        data: [{ label: "Nov", value: 1200, date: "2026-11-12" }],
      },
    ];

    expect(
      chartHoverText(
        series,
        { seriesName: "Revenue", name: "Nov", value: 1200 },
        { locale: "th", timeZone: "Asia/Bangkok" },
      ),
    ).toBe("Nov: 1,200 · 12 พ.ย. 2569");
  });
});

describe("chartTableRows", () => {
  it("offers the full data with formatted dates and numbers", () => {
    const series: ChartSeries[] = [
      {
        name: "Revenue",
        type: "pie",
        data: [{ label: "Nov", value: 1200, date: "2026-11-12" }],
      },
    ];

    expect(chartTableRows(series, { locale: "th", timeZone: "Asia/Bangkok" })).toEqual([
      {
        series: "Revenue",
        label: "Nov",
        date: "12 พ.ย. 2569",
        value: "1,200",
      },
    ]);
  });
});
