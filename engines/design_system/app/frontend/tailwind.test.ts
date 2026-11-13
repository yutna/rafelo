import { describe, expect, it } from "vitest";

import { twMerge } from "./internal/tailwind";

describe("tailwind merge", () => {
  it("keeps a custom token and a semantic color of the same prefix", () => {
    expect(twMerge("text-primary text-display")).toBe("text-primary text-display");
    expect(twMerge("shadow-danger shadow-card")).toBe("shadow-danger shadow-card");
  });
});
