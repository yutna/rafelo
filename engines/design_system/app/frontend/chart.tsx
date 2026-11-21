import { lazy, Suspense } from "react";

import type { ChartProps } from "./chart.types";

import { t } from "./i18n";
import { useLocale } from "./i18n_provider";
import { Skeleton } from "./skeleton";

const ChartImpl = lazy(() => import("./chart_impl"));

export function Chart(props: ChartProps) {
  const { locale, timeZone } = useLocale();
  const labels = {
    empty: t("chart.empty"),
    error: t("chart.error"),
    showTable: t("chart.show_table"),
    hideTable: t("chart.hide_table"),
    tableCaption: t("chart.table_caption"),
    series: t("chart.series"),
    label: t("chart.label"),
    date: t("chart.date"),
    value: t("chart.value"),
  };

  return (
    <Suspense fallback={<Skeleton testId={`${props.testId}.loading`} />}>
      <ChartImpl {...props} locale={locale} timeZone={timeZone} labels={labels} />
    </Suspense>
  );
}
