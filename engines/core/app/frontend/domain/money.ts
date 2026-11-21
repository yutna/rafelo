import type { MoneyPlain } from "./money.types";

import { DomainError } from "./domain_error";

export class Money {
  private constructor(
    readonly minor: number,
    readonly currency: string,
    readonly exponent: number,
  ) {}

  static of(minor: number, currency: string, exponent = 2): Money {
    if (!Number.isInteger(minor)) throw new DomainError("money.minor_not_integer");
    if (!Number.isInteger(exponent) || exponent < 0 || exponent > 4)
      throw new DomainError("money.invalid_exponent");
    return new Money(minor, currency, exponent);
  }

  static fromPlain(plain: MoneyPlain): Money {
    return Money.of(plain.minor, plain.currency, plain.exponent);
  }

  toPlain(): MoneyPlain {
    return { minor: this.minor, currency: this.currency, exponent: this.exponent };
  }

  add(other: Money): Money {
    if (other.currency !== this.currency) throw new DomainError("money.currency_mismatch");
    if (other.exponent !== this.exponent) throw new DomainError("money.exponent_mismatch");
    return Money.of(this.minor + other.minor, this.currency, this.exponent);
  }

  multiply(quantity: number): Money {
    if (!Number.isInteger(quantity) || quantity < 0)
      throw new DomainError("money.invalid_quantity");
    return Money.of(this.minor * quantity, this.currency, this.exponent);
  }
}
