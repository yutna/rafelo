import { describe, expect, it } from "vitest";

import { calendarFor, formatDate, formatDateTime, formatMoney, formatNumber } from "./formatters";

describe("calendar dates", () => {
  it("keeps the calendar date in zones behind and ahead of UTC", () => {
    expect(formatDate("2026-11-11", "en", "America/Los_Angeles")).toContain("Nov 11");
    expect(formatDate("2026-11-11", "en", "Pacific/Kiritimati")).toContain("Nov 11");
    expect(formatDate("2026-11-11", "th", "Asia/Bangkok")).toContain("2569");
  });

  it("uses the Buddhist calendar and a BE year in Thai", () => {
    expect(calendarFor("th")).toBe("th-TH-u-ca-buddhist");
    expect(formatDate("2026-11-11", "th")).toContain("2569");
  });

  it("keeps the Gregorian year in English and formats numbers", () => {
    expect(formatDate("2026-11-11", "en")).toContain("2026");
    expect(formatNumber(1234.5, "en")).toBe("1,234.5");
  });
});

describe("instants", () => {
  it("formats an instant in the explicit zone and shifts the date", () => {
    expect(formatDate("2026-11-10T18:00:00Z", "en", "Asia/Bangkok")).toContain("Nov 11");
    expect(formatDate("2026-11-11T02:00:00Z", "en", "America/Los_Angeles")).toContain("Nov 10");
  });

  it("formats a date-time across the spring-forward edge", () => {
    expect(formatDateTime("2026-03-08T09:30:00Z", "en", "America/Los_Angeles")).toMatch(
      /Mar 8, 2026.*1:30/,
    );
    expect(formatDateTime("2026-03-08T10:30:00Z", "en", "America/Los_Angeles")).toMatch(
      /Mar 8, 2026.*3:30/,
    );
  });

  it("formats a date-time across the fall-back edge", () => {
    expect(formatDateTime("2026-11-01T08:30:00Z", "en", "America/Los_Angeles")).toMatch(
      /Nov 1, 2026.*1:30/,
    );
    expect(formatDateTime("2026-11-01T10:30:00Z", "en", "America/Los_Angeles")).toMatch(
      /Nov 1, 2026.*2:30/,
    );
  });

  it("shows a date-time in the Buddhist calendar in Thai", () => {
    expect(formatDateTime("2026-11-11T12:00:00Z", "th", "Asia/Bangkok")).toContain("2569");
  });
});

it("formats money with the currency exponent", () => {
  expect(formatMoney(1234, "THB", 2, "en")).toContain("12.34");
  expect(formatMoney(1234, "JPY", 0, "en")).toContain("1,234");
});
