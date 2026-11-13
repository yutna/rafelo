import type { DateRangePlain } from "./date_range.types";
import type { MoneyPlain } from "./money.types";

export type PricedRangePlain = {
  range: DateRangePlain;
  rate: MoneyPlain;
};
