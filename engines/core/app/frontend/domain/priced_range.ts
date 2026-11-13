import { DateRange } from "./date_range";
import { Money } from "./money";
import type { PricedRangePlain } from "./priced_range.types";

export class PricedRange {
  private constructor(
    readonly range: DateRange,
    readonly rate: Money,
  ) {}

  static of(range: DateRange, rate: Money): PricedRange {
    return new PricedRange(range, rate);
  }

  static fromPlain(plain: PricedRangePlain): PricedRange {
    return PricedRange.of(DateRange.fromPlain(plain.range), Money.fromPlain(plain.rate));
  }

  toPlain(): PricedRangePlain {
    return { range: this.range.toPlain(), rate: this.rate.toPlain() };
  }

  total(quantity: number): Money {
    return this.rate.multiply(quantity);
  }
}
