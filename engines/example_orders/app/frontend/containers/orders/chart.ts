import type { chartSchema } from "@core/contracts/page_props.schema";
import type { ChartOption } from "@design_system/public";
import type { z } from "zod";

type OrdersChart = z.infer<typeof chartSchema>;

export function ordersChartOption(chart: OrdersChart): ChartOption {
  return { series: chart.series };
}
