import { describe, expect, it } from "vitest";

import { DomainError } from "./domain_error";
import { Money } from "./money";

describe("Money", () => {
  it("round-trips its plain form and adds matching currencies", () => {
    const money = Money.of(1050, "THB");
    expect(Money.fromPlain(money.toPlain()).toPlain()).toEqual(money.toPlain());
    expect(money.add(Money.of(250, "THB")).minor).toBe(1300);
  });

  it("throws only for invariants", () => {
    expect(() => Money.of(1.5, "THB")).toThrow(DomainError);
    expect(() => Money.of(1, "THB").add(Money.of(1, "USD"))).toThrow(/currency_mismatch/);
  });
});
