import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

vi.mock("./chart_impl", () => ({
  default: () => <div data-testid="chart.impl" />,
}));

import { Chart } from "./chart";
import { I18nProvider } from "./i18n_provider";

describe("Chart wrapper", () => {
  it("shows its loading state until the lazy implementation arrives", async () => {
    render(
      <I18nProvider locale="en" timeZone="UTC">
        <Chart testId="lazy.chart" ariaLabel="Lazy chart" option={{ series: [] }} />
      </I18nProvider>,
    );

    expect(screen.getByTestId("lazy.chart.loading")).toBeInTheDocument();
    expect(await screen.findByTestId("chart.impl")).toBeInTheDocument();
    expect(screen.queryByTestId("lazy.chart.loading")).not.toBeInTheDocument();
  });
});
