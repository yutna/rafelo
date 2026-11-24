import type { ChartOption } from "@design_system/public";

export function catalogChartOption(seriesLabel: string): ChartOption {
  return {
    series: [
      {
        name: seriesLabel,
        type: "pie",
        data: [
          { label: "A", value: 1 },
          { label: "B", value: 2 },
        ],
      },
    ],
  };
}
