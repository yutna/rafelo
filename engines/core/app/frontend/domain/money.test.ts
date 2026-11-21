import { describe, expect, it } from "vitest";

import { DomainError } from "./domain_error";
import { Money } from "./money";

describe("Money", () => {
  it("round-trips its plain form and adds matching currencies", () => {
    const money = Money.of(1050, "THB");
    expect(Money.fromPlain(money.toPlain()).toPlain()).toEqual(money.toPlain());
    expect(money.add(Money.of(250, "THB")).minor).toBe(1300);
  });

  it("carries the currency exponent through the plain form", () => {
    expect(Money.of(1234, "JPY", 0).toPlain()).toEqual({
      minor: 1234,
      currency: "JPY",
      exponent: 0,
    });
    expect(Money.of(1234, "KWD", 3).toPlain()).toEqual({
      minor: 1234,
      currency: "KWD",
      exponent: 3,
    });
    expect(Money.fromPlain({ minor: 1234, currency: "KWD", exponent: 3 }).toPlain()).toEqual({
      minor: 1234,
      currency: "KWD",
      exponent: 3,
    });
  });

  it("throws only for invariants", () => {
    expect(() => Money.of(1.5, "THB")).toThrow(DomainError);
    expect(() => Money.of(1, "THB", 5)).toThrow(/invalid_exponent/);
    expect(() => Money.of(1, "THB").add(Money.of(1, "USD"))).toThrow(/currency_mismatch/);
    expect(() => Money.of(1, "THB").add(Money.of(1, "THB", 0))).toThrow(/exponent_mismatch/);
  });
});
