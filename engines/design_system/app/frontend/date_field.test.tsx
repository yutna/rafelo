import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { DateField } from "./date_field";

describe("DateField", () => {
  it("converts a Thai Buddhist Era entry to ISO Gregorian", async () => {
    const onChange = vi.fn();
    render(<DateField label="Date" value="2026-11-11" min="2026-01-01" max="2026-12-31" onChange={onChange} locale="th" />);
    const input = screen.getByRole("textbox");

    expect((input as HTMLInputElement).value).toBe("11/11/2569");
    await userEvent.clear(input);
    await userEvent.type(input, "12/11/2569");

    expect(onChange).toHaveBeenCalledWith("2026-11-12");
  });

  it("refuses a Gregorian year typed in Thai", async () => {
    const onChange = vi.fn();
    render(<DateField label="Date" value="2026-11-11" min="2026-01-01" max="2026-12-31" onChange={onChange} locale="th" />);
    const input = screen.getByRole("textbox");

    await userEvent.clear(input);
    await userEvent.type(input, "11/11/2026");

    expect(onChange).not.toHaveBeenCalled();
  });
});
