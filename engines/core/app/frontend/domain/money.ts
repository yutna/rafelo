import { DomainError } from "./domain_error";
import type { MoneyPlain } from "./money.types";

export class Money {
  private constructor(
    readonly minor: number,
    readonly currency: string,
  ) {}

  static of(minor: number, currency: string): Money {
    if (!Number.isInteger(minor)) throw new DomainError("money.minor_not_integer");
    return new Money(minor, currency);
  }

  static fromPlain(plain: MoneyPlain): Money {
    return Money.of(plain.minor, plain.currency);
  }

  toPlain(): MoneyPlain {
    return { minor: this.minor, currency: this.currency };
  }

  add(other: Money): Money {
    if (other.currency !== this.currency) throw new DomainError("money.currency_mismatch");
    return Money.of(this.minor + other.minor, this.currency);
  }

  multiply(quantity: number): Money {
    if (!Number.isInteger(quantity) || quantity < 0) throw new DomainError("money.invalid_quantity");
    return Money.of(this.minor * quantity, this.currency);
  }
}
