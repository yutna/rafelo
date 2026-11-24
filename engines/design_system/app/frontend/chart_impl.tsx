import { PieChart } from "echarts/charts";
import { AriaComponent } from "echarts/components";
import * as echarts from "echarts/core";
import { CanvasRenderer } from "echarts/renderers";
import { useEffect, useRef, useState } from "react";

import type { ChartImplProps } from "./chart.types";

import { chartTheme } from "./chart_color";
import { buildChartOption, chartHoverText, chartTableRows } from "./chart_option";

echarts.use([PieChart, AriaComponent, CanvasRenderer]);

export default function ChartImpl({
  testId,
  ariaLabel,
  description,
  option,
  locale,
  timeZone,
  labels,
}: ChartImplProps) {
  const series = option.series;
  const ref = useRef<HTMLDivElement>(null);
  const chartRef = useRef<ReturnType<typeof echarts.init> | null>(null);
  const contextRef = useRef({ series, locale, timeZone });
  const [failed, setFailed] = useState(false);
  const [showTable, setShowTable] = useState(false);
  const [hover, setHover] = useState("");
  const empty = series.length === 0 || series.every((entry) => entry.data.length === 0);

  useEffect(() => {
    if (!ref.current) return;
    try {
      const chart = echarts.init(ref.current, chartTheme(getComputedStyle(ref.current)));
      chartRef.current = chart;
      chart.on("mouseover", (params) => {
        setHover(chartHoverText(contextRef.current.series, params, contextRef.current));
      });
      chart.on("mouseout", () => setHover(""));
      const observer =
        typeof ResizeObserver === "undefined"
          ? null
          : new ResizeObserver(() => {
              chart.resize();
            });
      observer?.observe(ref.current);
      return () => {
        observer?.disconnect();
        chart.dispose();
        chartRef.current = null;
      };
    } catch {
      setTimeout(() => setFailed(true), 0);
    }
  }, []);

  useEffect(() => {
    contextRef.current = { series, locale, timeZone };
  }, [locale, series, timeZone]);

  useEffect(() => {
    const chart = chartRef.current;
    if (!chart || empty) return;

    try {
      chart.setOption(
        buildChartOption(series, {
          locale,
          timeZone,
          description: description ?? ariaLabel,
        }),
        { notMerge: true },
      );
    } catch {
      setTimeout(() => setFailed(true), 0);
    }
  }, [ariaLabel, description, empty, locale, series, timeZone]);

  const rows = chartTableRows(series, { locale, timeZone });

  return (
    <div data-testid={`${testId}.container`}>
      <div ref={ref} data-testid={testId} hidden={empty || failed} className="h-64 w-full" />
      {hover ? (
        <p role="status" data-testid={`${testId}.tooltip`} className="text-sm text-slate-600">
          {hover}
        </p>
      ) : null}
      {empty ? (
        <p role="status" data-testid={`${testId}.empty`} className="text-sm text-slate-600">
          {labels.empty}
        </p>
      ) : null}
      {failed ? (
        <p role="alert" data-testid={`${testId}.error`} className="text-sm text-red-700">
          {labels.error}
        </p>
      ) : null}
      {empty ? null : (
        <>
          <button
            type="button"
            data-testid={`${testId}.table.toggle`}
            aria-expanded={showTable}
            onClick={() => setShowTable((shown) => !shown)}
            className="mt-2 text-sm underline"
          >
            {showTable ? labels.hideTable : labels.showTable}
          </button>
          {showTable ? (
            <table data-testid={`${testId}.table`} className="mt-2 w-full text-left text-sm">
              <caption className="sr-only">{labels.tableCaption}</caption>
              <thead>
                <tr>
                  <th scope="col">{labels.series}</th>
                  <th scope="col">{labels.label}</th>
                  <th scope="col">{labels.date}</th>
                  <th scope="col">{labels.value}</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row, index) => (
                  <tr key={`${row.series}-${row.label}-${index}`}>
                    <td>{row.series}</td>
                    <td>{row.label}</td>
                    <td>{row.date}</td>
                    <td>{row.value}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : null}
        </>
      )}
    </div>
  );
}
