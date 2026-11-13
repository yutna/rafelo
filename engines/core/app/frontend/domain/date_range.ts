import { DomainError } from "./domain_error";
import type { DateRangePlain } from "./date_range.types";

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

export class DateRange {
  private constructor(
    readonly start: string,
    readonly end: string,
  ) {}

  static of(start: string, end: string): DateRange {
    if (!ISO_DATE.test(start) || !ISO_DATE.test(end)) throw new DomainError("date_range.invalid_iso");
    return new DateRange(start, end);
  }

  static fromPlain(plain: DateRangePlain): DateRange {
    return DateRange.of(plain.start, plain.end);
  }

  toPlain(): DateRangePlain {
    return { start: this.start, end: this.end };
  }

  issues(): string[] {
    return this.start > this.end ? [ "date_range.end_before_start" ] : [];
  }

  contains(date: string): boolean {
    return this.issues().length === 0 && date >= this.start && date <= this.end;
  }
}
