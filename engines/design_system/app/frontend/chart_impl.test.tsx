import { act, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

const echarts = vi.hoisted(() => {
  const instance = {
    on: vi.fn(),
    off: vi.fn(),
    setOption: vi.fn(),
    resize: vi.fn(),
    dispose: vi.fn(),
  };
  return {
    instance,
    init: vi.fn(() => instance),
    use: vi.fn(),
  };
});
const observer = vi.hoisted(() => ({ observe: vi.fn(), disconnect: vi.fn() }));

vi.mock("echarts/core", () => ({ init: echarts.init, use: echarts.use }));
vi.mock("echarts/charts", () => ({ BarChart: {}, LineChart: {}, PieChart: {} }));
vi.mock("echarts/components", () => ({
  AriaComponent: {},
  GridComponent: {},
  LegendComponent: {},
  TooltipComponent: {},
}));
vi.mock("echarts/renderers", () => ({ CanvasRenderer: {} }));

import type { ChartLabels, ChartSeries } from "./chart.types";

import ChartImpl from "./chart_impl";

const labels: ChartLabels = {
  empty: "No data to chart",
  error: "The chart could not be displayed",
  showTable: "Show as table",
  hideTable: "Hide table",
  tableCaption: "Chart data",
  series: "Series",
  label: "Label",
  date: "Date",
  value: "Value",
};

class ResizeObserverMock {
  observe = observer.observe;
  disconnect = observer.disconnect;
}

vi.stubGlobal("ResizeObserver", ResizeObserverMock);

const series: ChartSeries[] = [
  {
    name: "Orders",
    type: "pie",
    data: [
      { label: "Open", value: 1200 },
      { label: "Paid", value: 300 },
    ],
  },
];

function renderChart(next: ChartSeries[] = series) {
  return render(
    <ChartImpl
      testId="orders.chart"
      ariaLabel="Orders by status"
      series={next}
      locale="en"
      timeZone="UTC"
      labels={labels}
    />,
  );
}

describe("ChartImpl", () => {
  it("initialises once, sets the option with notMerge, and disposes on unmount", () => {
    const { rerender, unmount } = renderChart();

    expect(echarts.init).toHaveBeenCalledTimes(1);
    expect(observer.observe).toHaveBeenCalledWith(screen.getByTestId("orders.chart"));
    expect(echarts.instance.setOption).toHaveBeenLastCalledWith(
      expect.objectContaining({ aria: expect.objectContaining({ enabled: true }) }),
      { notMerge: true },
    );

    rerender(
      <ChartImpl
        testId="orders.chart"
        ariaLabel="Orders by status"
        series={[{ ...series[0]!, data: [{ label: "Paid", value: 900 }] }]}
        locale="en"
        timeZone="UTC"
        labels={labels}
      />,
    );

    expect(echarts.init).toHaveBeenCalledTimes(1);
    expect(echarts.instance.setOption).toHaveBeenCalledTimes(2);
    expect(echarts.instance.setOption).toHaveBeenLastCalledWith(expect.anything(), {
      notMerge: true,
    });

    unmount();

    expect(observer.disconnect).toHaveBeenCalledTimes(1);
    expect(echarts.instance.dispose).toHaveBeenCalledTimes(1);
  });

  it("renders the empty state without setting an option", () => {
    echarts.instance.setOption.mockClear();
    renderChart([]);

    expect(screen.getByTestId("orders.chart.empty")).toHaveTextContent("No data to chart");
    expect(echarts.instance.setOption).not.toHaveBeenCalled();
  });

  it("renders the error state when ECharts cannot initialise", async () => {
    echarts.init.mockImplementationOnce(() => {
      throw new Error("boom");
    });
    renderChart();

    expect(await screen.findByTestId("orders.chart.error")).toHaveTextContent(
      "The chart could not be displayed",
    );
  });

  it("offers the data as a table with formatted values", async () => {
    renderChart();

    const toggle = screen.getByTestId("orders.chart.table.toggle");
    expect(toggle).toHaveTextContent("Show as table");
    expect(screen.queryByTestId("orders.chart.table")).not.toBeInTheDocument();

    await userEvent.click(toggle);

    const table = screen.getByTestId("orders.chart.table");
    expect(toggle).toHaveTextContent("Hide table");
    expect(
      within(table)
        .getAllByRole("cell")
        .map((cell) => cell.textContent),
    ).toEqual(["Orders", "Open", "", "1,200", "Orders", "Paid", "", "300"]);
  });

  it("formats the hovered point for the live tooltip", () => {
    renderChart();

    const handler = echarts.instance.on.mock.calls.find(([event]) => event === "mouseover")?.[1] as
      ((params: { seriesName: string; name: string; value: number }) => void) | undefined;
    expect(handler).toBeDefined();

    act(() => {
      handler?.({ seriesName: "Orders", name: "Open", value: 1200 });
    });

    expect(screen.getByTestId("orders.chart.tooltip")).toHaveTextContent("Open: 1,200");
  });

  it("exposes the chart as one labelled image", () => {
    renderChart();

    expect(screen.getByTestId("orders.chart")).toHaveAttribute("role", "img");
    expect(screen.getByTestId("orders.chart")).toHaveAttribute("aria-label", "Orders by status");
  });
});
