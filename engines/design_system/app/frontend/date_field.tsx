import type { DateValue } from "@internationalized/date";

import { CalendarDate, GregorianCalendar, parseDate, toCalendar } from "@internationalized/date";
import {
  Button as AriaButton,
  Calendar,
  CalendarCell,
  CalendarGrid,
  DateInput,
  DatePicker,
  DateSegment,
  Dialog,
  Group,
  Heading,
  Label,
  Popover,
} from "react-aria-components";

import { isValidIsoDate } from "./formatters";
import { useLocale } from "./i18n_provider";

type DateFieldProps = {
  label: string;
  value: string;
  min: string;
  max: string;
  onChange: (isoDate: string) => void;
  locale?: string;
  name?: string;
};

function toCalendarDate(iso: string): CalendarDate | null {
  return isValidIsoDate(iso) ? parseDate(iso) : null;
}

function toIso(date: DateValue): string {
  return date instanceof CalendarDate
    ? toCalendar(date, new GregorianCalendar()).toString()
    : date.toString();
}

export function DateField({ label, value, min, max, onChange, name }: DateFieldProps) {
  const { locale } = useLocale();

  return (
    <DatePicker
      aria-label={label}
      name={name}
      value={toCalendarDate(value)}
      minValue={toCalendarDate(min) ?? undefined}
      maxValue={toCalendarDate(max) ?? undefined}
      onChange={(date) => {
        if (date) onChange(toIso(date));
      }}
      className="block text-sm font-medium text-slate-700"
    >
      <Label>{label}</Label>
      <Group className="mt-1 flex items-center rounded border border-slate-300 px-3 py-2">
        <DateInput className="flex-1">
          {(segment) => <DateSegment segment={segment} data-testid={`date.${segment.type}`} />}
        </DateInput>
        <AriaButton className="ml-2 text-slate-600" aria-label={label}>
          ▾
        </AriaButton>
      </Group>
      <Popover>
        <Dialog>
          <Calendar aria-label={`${label} (${locale})`}>
            <header className="flex items-center justify-between pb-2">
              <AriaButton slot="previous">◀</AriaButton>
              <Heading />
              <AriaButton slot="next">▶</AriaButton>
            </header>
            <CalendarGrid>{(date) => <CalendarCell date={date} />}</CalendarGrid>
          </Calendar>
        </Dialog>
      </Popover>
    </DatePicker>
  );
}
