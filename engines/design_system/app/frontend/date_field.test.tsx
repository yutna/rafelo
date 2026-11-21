import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { DateField } from "./date_field";
import { I18nProvider } from "./i18n_provider";

describe("DateField", () => {
  it("renders the value in the locale calendar", () => {
    render(
      <I18nProvider locale="th" timeZone="Asia/Bangkok">
        <DateField
          testId="appointment"
          label="Date"
          value="2026-11-11"
          min="2026-01-01"
          max="2026-12-31"
          onChange={() => {}}
        />
      </I18nProvider>,
    );

    expect(screen.getByTestId("appointment.year")).toHaveTextContent("2569");
    expect(screen.getByTestId("appointment.month")).toHaveTextContent("11");
    expect(screen.getByTestId("appointment.day")).toHaveTextContent("11");
  });

  it("keeps the displayed value in sync when the props change", () => {
    const { rerender } = render(
      <I18nProvider locale="en" timeZone="UTC">
        <DateField
          testId="date"
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
          testId="date"
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
            testId="date"
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

  it("keeps two fields on one page apart", () => {
    render(
      <I18nProvider locale="en" timeZone="UTC">
        <DateField
          testId="start"
          label="Start"
          value="2026-11-11"
          min="2026-01-01"
          max="2026-12-31"
          onChange={() => {}}
        />
        <DateField
          testId="end"
          label="End"
          value="2026-11-12"
          min="2026-01-01"
          max="2026-12-31"
          onChange={() => {}}
        />
      </I18nProvider>,
    );

    expect(screen.getByTestId("start.day")).toHaveTextContent("11");
    expect(screen.getByTestId("end.day")).toHaveTextContent("12");
  });

  async function typeDate(parts: { year: string; month: string; day: string }) {
    await userEvent.click(screen.getByTestId("date.year"));
    await userEvent.keyboard(parts.year);
    await userEvent.click(screen.getByTestId("date.month"));
    await userEvent.keyboard(parts.month);
    await userEvent.click(screen.getByTestId("date.day"));
    await userEvent.keyboard(parts.day);
  }

  it("converts a typed Buddhist Era entry to ISO Gregorian", async () => {
    const onChange = vi.fn();
    render(
      <I18nProvider locale="th" timeZone="Asia/Bangkok">
        <DateField
          testId="date"
          label="Date"
          value=""
          min="2026-01-01"
          max="2026-12-31"
          onChange={onChange}
        />
      </I18nProvider>,
    );

    await typeDate({ year: "2569", month: "11", day: "12" });

    await waitFor(() => expect(onChange).toHaveBeenLastCalledWith("2026-11-12"));
    expect(onChange).not.toHaveBeenCalledWith("1483-11-12");
  });

  it("refuses a Gregorian year typed under the Buddhist calendar", async () => {
    const onChange = vi.fn();
    render(
      <I18nProvider locale="th" timeZone="Asia/Bangkok">
        <DateField
          testId="date"
          label="Date"
          value=""
          min="2026-01-01"
          max="2026-12-31"
          onChange={onChange}
        />
      </I18nProvider>,
    );

    await typeDate({ year: "2026", month: "11", day: "11" });
    await userEvent.click(document.body);
    await new Promise((resolve) => setTimeout(resolve, 350));

    expect(onChange).not.toHaveBeenCalled();
  });

  it("refuses an impossible typed date", async () => {
    const onChange = vi.fn();
    render(
      <I18nProvider locale="th" timeZone="Asia/Bangkok">
        <DateField
          testId="date"
          label="Date"
          value="2026-11-11"
          min="2026-01-01"
          max="2026-12-31"
          onChange={onChange}
        />
      </I18nProvider>,
    );

    await userEvent.click(screen.getByTestId("date.month"));
    await userEvent.keyboard("02");
    await userEvent.click(screen.getByTestId("date.day"));
    await userEvent.keyboard("31");
    await userEvent.click(document.body);

    await waitFor(() => expect(screen.getByTestId("date.day")).toHaveTextContent("11"));
    expect(onChange).not.toHaveBeenCalled();
  });

  it("does not submit a changed date when a segment is cleared", async () => {
    const onChange = vi.fn();
    render(
      <I18nProvider locale="en" timeZone="UTC">
        <DateField
          testId="date"
          label="Date"
          value="2026-11-11"
          min="2026-01-01"
          max="2026-12-31"
          onChange={onChange}
        />
      </I18nProvider>,
    );

    await userEvent.click(screen.getByTestId("date.day"));
    await userEvent.keyboard("{Backspace}");
    await userEvent.tab();

    expect(onChange).not.toHaveBeenCalled();
  });

  it("rejects an invalid min or max", () => {
    expect(() =>
      render(
        <I18nProvider locale="en" timeZone="UTC">
          <DateField
            testId="date"
            label="Date"
            value="2026-11-11"
            min="not-a-date"
            max="2026-12-31"
            onChange={() => {}}
          />
        </I18nProvider>,
      ),
    ).toThrow("valid ISO min and max");
  });

  it("rejects an impossible calendar date", () => {
    render(
      <I18nProvider locale="en" timeZone="UTC">
        <DateField
          testId="date"
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
