import { DateRange } from "../domain/date_range";
import type { DateRangeFormPlain } from "./date_range_form.types";

export class DateRangeForm {
  private constructor(readonly plain: DateRangeFormPlain) {}

  static fromPlain(plain: DateRangeFormPlain): DateRangeForm {
    return new DateRangeForm({ ...plain });
  }

  issues(): string[] {
    return DateRange.fromPlain(this.plain).issues();
  }

  toPlain(): DateRangeFormPlain {
    return { ...this.plain };
  }

  toPayload(): DateRangeFormPlain | null {
    return this.issues().length === 0 ? this.toPlain() : null;
  }
}
