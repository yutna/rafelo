import { useState } from "react";

import { assertPlain } from "./assert_plain";
import { deepFreeze } from "./deep_freeze";

export function useUiState<T extends object>(initial: T) {
  if (import.meta.env.DEV) {
    assertPlain(initial);
    deepFreeze(initial);
  }
  const [state, setState] = useState<T>(initial);

  function update(patch: Partial<T>) {
    if (import.meta.env.DEV) {
      assertPlain(patch);
      deepFreeze(patch);
    }
    setState((current) => {
      const next = { ...current, ...patch };
      if (import.meta.env.DEV) Object.freeze(next);
      return next;
    });
  }

  return [state, update] as const;
}
