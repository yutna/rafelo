import { useReducer } from "react";

import { assertPlain } from "./assert_plain";
import { deepFreeze } from "./deep_freeze";

export function useDomainReducer<S extends object, E extends { type: string }>(
  reducer: (state: S, event: E) => S,
  initialPlain: S,
) {
  if (import.meta.env.DEV) {
    assertPlain(initialPlain);
    deepFreeze(initialPlain);
  }

  return useReducer((state: S, event: E): S => {
    const next = reducer(state, event);
    if (import.meta.env.DEV) {
      assertPlain(next);
      deepFreeze(next);
    }
    return next;
  }, initialPlain);
}
