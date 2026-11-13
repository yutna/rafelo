import { describe, expect, it } from "vitest";

import { DateRangeForm } from "./date_range_form";

describe("DateRangeForm", () => {
  it("reports blank and reversed input without throwing", () => {
    expect(DateRangeForm.fromPlain({ start: "", end: "" }).issues()).toEqual([ "date_range.start_invalid", "date_range.end_invalid" ]);
    expect(DateRangeForm.fromPlain({ start: "2026-11-12", end: "2026-11-11" }).issues()).toEqual([ "date_range.end_before_start" ]);
    expect(DateRangeForm.fromPlain({ start: "2026-02-31", end: "2026-03-01" }).issues()).toEqual([ "date_range.start_invalid" ]);
  });

  it("returns the payload only when valid", () => {
    const form = DateRangeForm.fromPlain({ start: "2026-11-01", end: "2026-11-30" });
    expect(form.toPayload()).toEqual({ start: "2026-11-01", end: "2026-11-30" });
    expect(DateRangeForm.fromPlain(form.toPlain()).toPlain()).toEqual(form.toPlain());
  });
});
