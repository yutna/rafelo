import type { ChartPoint, ChartSeries } from "./chart.types";

import { formatDate, formatNumber } from "./formatters";

type FormatContext = {
  locale: string;
  timeZone: string;
  description: string;
};

export function buildChartOption(
  series: ChartSeries[],
  context: FormatContext,
): Record<string, unknown> {
  return {
    aria: { enabled: true, label: { description: context.description } },
    series: series.map((entry) => ({
      type: "pie",
      name: entry.name,
      radius: "60%",
      label: {
        formatter: (params: { name: string; value: number }) =>
          `${params.name}: ${formatNumber(Number(params.value), context.locale)}`,
      },
      data: entry.data.map((point) => ({ name: point.label, value: point.value })),
    })),
  };
}

export function chartHoverText(
  series: ChartSeries[],
  params: { seriesName?: string; name?: string; value?: unknown; dataIndex?: number },
  context: Pick<FormatContext, "locale" | "timeZone">,
): string {
  const entry = series.find((candidate) => candidate.name === params.seriesName);
  const point =
    entry?.data.find((candidate) => candidate.label === params.name) ??
    (params.dataIndex === undefined ? undefined : entry?.data[params.dataIndex]);
  if (!point) return "";

  const parts = [`${point.label}: ${formatNumber(point.value, context.locale)}`];
  if (point.date) parts.push(formatDate(point.date, context.locale, context.timeZone));
  return parts.join(" · ");
}

export function chartTableRows(
  series: ChartSeries[],
  context: Pick<FormatContext, "locale" | "timeZone">,
): { series: string; label: string; date: string; value: string }[] {
  return series.flatMap((entry) =>
    entry.data.map((point) => ({
      series: entry.name,
      label: point.label,
      date: point.date ? formatDate(point.date, context.locale, context.timeZone) : "",
      value: formatNumber(point.value, context.locale),
    })),
  );
}

export type { ChartPoint };
