import { describe, expect, it } from "vitest";

import { themeTokens, twMerge } from "./internal/tailwind";

describe("tailwind merge", () => {
  const groups = [
    { group: "text", classPrefix: "text", semantic: "text-primary" },
    { group: "shadow", classPrefix: "shadow", semantic: "shadow-danger" },
  ] as const;

  it("keeps every custom token beside a semantic color of the same prefix", () => {
    for (const { group, classPrefix, semantic } of groups) {
      for (const token of themeTokens[group]) {
        expect(twMerge(`${semantic} ${classPrefix}-${token}`)).toBe(
          `${semantic} ${classPrefix}-${token}`,
        );
      }
    }
  });

  it("lets a custom radius replace a semantic radius", () => {
    for (const token of themeTokens.radius) {
      expect(twMerge(`rounded-lg rounded-${token}`)).toBe(`rounded-${token}`);
    }
  });
});
