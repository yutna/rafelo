import { DateRange } from "../domain/date_range";

export type DateRangeFormPlain = {
  start: string;
  end: string;
};

export class DateRangeForm {
  private constructor(readonly plain: DateRangeFormPlain) {}

  static fromPlain(plain: DateRangeFormPlain): DateRangeForm {
    return new DateRangeForm(plain);
  }

  issues(): string[] {
    const codes: string[] = [];
    if (!this.plain.start) codes.push("date_range.start_blank");
    if (!this.plain.end) codes.push("date_range.end_blank");
    if (codes.length > 0) return codes;
    return DateRange.of(this.plain.start, this.plain.end).issues();
  }

  toPayload(): DateRangeFormPlain | null {
    return this.issues().length === 0 ? this.plain : null;
  }
}
