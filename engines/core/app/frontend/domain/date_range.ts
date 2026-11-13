import { DomainError } from "./domain_error";
import type { DateRangePlain } from "./date_range.types";

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

function validCalendarDate(value: string): boolean {
  if (!ISO_DATE.test(value)) return false;
  const [year, month, day] = value.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}

export class DateRange {
  private constructor(
    readonly start: string,
    readonly end: string,
  ) {}

  static of(start: string, end: string): DateRange {
    if (typeof start !== "string" || typeof end !== "string") throw new DomainError("date_range.not_a_string");
    return new DateRange(start, end);
  }

  static fromPlain(plain: DateRangePlain): DateRange {
    return DateRange.of(plain.start, plain.end);
  }

  toPlain(): DateRangePlain {
    return { start: this.start, end: this.end };
  }

  issues(): string[] {
    const codes: string[] = [];
    if (!validCalendarDate(this.start)) codes.push("date_range.start_invalid");
    if (!validCalendarDate(this.end)) codes.push("date_range.end_invalid");
    if (codes.length === 0 && this.start > this.end) codes.push("date_range.end_before_start");
    return codes;
  }

  contains(date: string): boolean {
    return this.issues().length === 0 && validCalendarDate(date) && date >= this.start && date <= this.end;
  }
}
