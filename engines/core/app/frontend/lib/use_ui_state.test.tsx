import { act, renderHook } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { useDomainReducer } from "./use_domain_reducer";
import { useUiState } from "./use_ui_state";

describe("useUiState", () => {
  it("patches an object state", () => {
    const { result } = renderHook(() => useUiState({ open: false }));
    act(() => result.current[1]({ open: true }));

    expect(result.current[0]).toEqual({ open: true });
  });
});

describe("useDomainReducer", () => {
  it("replaces state through the reducer", () => {
    const { result } = renderHook(() =>
      useDomainReducer(
        (state: { count: number }, event: { type: "increment" }) =>
          event.type === "increment" ? { count: state.count + 1 } : state,
        { count: 0 },
      ),
    );
    act(() => result.current[1]({ type: "increment" }));

    expect(result.current[0]).toEqual({ count: 1 });
  });
});
