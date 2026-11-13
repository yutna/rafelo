import { describe, expect, it } from "vitest";

import { assertPlain } from "./assert_plain";

describe("assertPlain", () => {
  it("accepts plain objects and arrays", () => {
    expect(() => assertPlain({ lines: [{ quantity: 1 }] })).not.toThrow();
  });

  it("names the first non-plain value", () => {
    expect(() => assertPlain({ line: new Date() }, "state")).toThrow(/state\.line is a Date/);
  });
});
