import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { DateField } from "./date_field";
import { I18nProvider } from "./i18n_provider";

describe("DateField", () => {
  it("renders the value in the locale calendar", () => {
    render(
      <I18nProvider locale="th" timeZone="Asia/Bangkok">
        <DateField
          label="Date"
          value="2026-11-11"
          min="2026-01-01"
          max="2026-12-31"
          onChange={() => {}}
        />
      </I18nProvider>,
    );

    expect(screen.getByTestId("date.year")).toHaveTextContent("2569");
    expect(screen.getByTestId("date.month")).toHaveTextContent("11");
    expect(screen.getByTestId("date.day")).toHaveTextContent("11");
  });

  it("keeps the displayed value in sync when the props change", () => {
    const { rerender } = render(
      <I18nProvider locale="en" timeZone="UTC">
        <DateField
          label="Date"
          value="2026-11-11"
          min="2026-01-01"
          max="2026-12-31"
          onChange={() => {}}
        />
      </I18nProvider>,
    );

    rerender(
      <I18nProvider locale="en" timeZone="UTC">
        <DateField
          label="Date"
          value="2026-12-25"
          min="2026-01-01"
          max="2026-12-31"
          onChange={() => {}}
        />
      </I18nProvider>,
    );

    expect(screen.getByTestId("date.year")).toHaveTextContent("2026");
    expect(screen.getByTestId("date.month")).toHaveTextContent("12");
    expect(screen.getByTestId("date.day")).toHaveTextContent("25");
  });

  it("submits Gregorian ISO even under the Buddhist calendar", () => {
    const onChange = vi.fn();
    render(
      <form data-testid="date-form">
        <I18nProvider locale="th" timeZone="Asia/Bangkok">
          <DateField
            label="Date"
            name="date"
            value="2026-11-11"
            min="2026-01-01"
            max="2026-12-31"
            onChange={onChange}
          />
        </I18nProvider>
      </form>,
    );

    const form = screen.getByTestId("date-form") as HTMLFormElement;
    expect((form.elements.namedItem("date") as HTMLInputElement).value).toBe("2026-11-11");
  });

  it("rejects an impossible calendar date", () => {
    render(
      <I18nProvider locale="en" timeZone="UTC">
        <DateField
          label="Date"
          value="2026-02-31"
          min="2026-01-01"
          max="2026-12-31"
          onChange={() => {}}
        />
      </I18nProvider>,
    );

    expect(screen.getByTestId("date.year")).toHaveTextContent("yyyy");
    expect(screen.getByTestId("date.month")).toHaveTextContent("mm");
    expect(screen.getByTestId("date.day")).toHaveTextContent("dd");
  });
});
