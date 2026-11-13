import { describe, expect, it } from "vitest";

import { DateRangeForm } from "./date_range_form";

describe("DateRangeForm", () => {
  it("reports blank and reversed input without throwing", () => {
    expect(DateRangeForm.fromPlain({ start: "", end: "" }).issues()).toEqual([ "date_range.start_blank", "date_range.end_blank" ]);
    expect(DateRangeForm.fromPlain({ start: "2026-11-12", end: "2026-11-11" }).issues()).toEqual([ "date_range.end_before_start" ]);
  });

  it("returns the payload only when valid", () => {
    expect(DateRangeForm.fromPlain({ start: "2026-11-01", end: "2026-11-30" }).toPayload()).toEqual({
      start: "2026-11-01",
      end: "2026-11-30",
    });
  });
});
