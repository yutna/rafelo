import { describe, expect, it } from "vitest";

import { deepFreeze } from "./deep_freeze";

describe("deepFreeze", () => {
  it("freezes nested plain data", () => {
    const value = { line: { quantity: 1 } };
    deepFreeze(value);

    expect(Object.isFrozen(value)).toBe(true);
    expect(Object.isFrozen(value.line)).toBe(true);
  });
});
