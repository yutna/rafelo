import type { DateRangePlain } from "@core/domain/date_range.types";

import { DateRange } from "@core/domain/date_range";
import { assertPlain } from "@core/lib/assert_plain";
import { useDomainReducer } from "@core/lib/use_domain_reducer";

type DateRangeEvent =
  { type: "start_changed"; start: string } | { type: "end_changed"; end: string };

function reducer(state: DateRangePlain, event: DateRangeEvent): DateRangePlain {
  const current = DateRange.fromPlain(state);
  switch (event.type) {
    case "start_changed":
      return DateRange.of(event.start, current.end).toPlain();
    case "end_changed":
      return DateRange.of(current.start, event.end).toPlain();
  }
}

export function useDateRange(initialPlain: DateRangePlain) {
  const [plain, dispatch] = useDomainReducer(reducer, initialPlain);
  const range = DateRange.fromPlain(plain);
  if (import.meta.env.DEV) assertPlain(range.toPlain());

  return {
    view: { plain: range.toPlain(), issues: range.issues() },
    setStart: (start: string) => dispatch({ type: "start_changed", start }),
    setEnd: (end: string) => dispatch({ type: "end_changed", end }),
  };
}
