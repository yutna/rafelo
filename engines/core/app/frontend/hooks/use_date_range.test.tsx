import { act, renderHook } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { assertPlain } from "../lib/assert_plain";
import { useDateRange } from "./use_date_range";

describe("useDateRange", () => {
  it("returns a plain view model and dispatchers", () => {
    const { result } = renderHook(() => useDateRange({ start: "2026-11-01", end: "2026-11-30" }));
    assertPlain(result.current.view);
    expect(result.current.view.issues).toEqual([]);

    act(() => result.current.setEnd("2026-10-10"));
    expect(result.current.view.issues).toEqual([ "date_range.end_before_start" ]);
  });
});
