import { describe, expect, it } from "vitest";

import { calendarFor, formatDate, formatMoney, formatNumber } from "./formatters";

describe("formatters", () => {
  it("uses the Buddhist calendar and a BE year in Thai", () => {
    expect(calendarFor("th")).toBe("th-TH-u-ca-buddhist");
    expect(formatDate("2026-11-11", "th")).toContain("2569");
  });

  it("keeps the Gregorian year in English and formats numbers", () => {
    expect(formatDate("2026-11-11", "en")).toContain("2026");
    expect(formatNumber(1234.5, "en")).toBe("1,234.5");
  });
});

  it("formats money with the currency exponent", () => {
    expect(formatMoney(1234, "THB", 2, "en")).toContain("12.34");
    expect(formatMoney(1234, "JPY", 0, "en")).toContain("1,234");
  });
