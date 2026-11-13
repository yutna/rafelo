import { BarChart } from "echarts/charts";
import * as echarts from "echarts/core";
import { CanvasRenderer } from "echarts/renderers";
import { useEffect, useRef } from "react";

echarts.use([ BarChart, CanvasRenderer ]);

type ChartProps = {
  testId: string;
  option: Record<string, unknown>;
  ariaLabel: string;
};

export default function ChartImpl({ testId, option, ariaLabel }: ChartProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!ref.current) return;
    const chart = echarts.init(ref.current);
    chart.setOption(option);
    const observer = new ResizeObserver(() => chart.resize());
    observer.observe(ref.current);
    return () => {
      observer.disconnect();
      chart.dispose();
    };
  }, [option]);

  return <div ref={ref} data-testid={testId} role="img" aria-label={ariaLabel} className="h-64 w-full" />;
}
