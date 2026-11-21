import type { CalendarIdentifier, DateValue } from "@internationalized/date";
import type { MutableRefObject } from "react";

import {
  CalendarDate,
  GregorianCalendar,
  createCalendar,
  parseDate,
  toCalendar,
} from "@internationalized/date";
import { useContext, useEffect, useRef, useState } from "react";
import {
  Button as AriaButton,
  Calendar,
  CalendarCell,
  CalendarGrid,
  DateFieldStateContext,
  DateInput,
  DatePicker,
  DateSegment,
  Dialog,
  Group,
  Heading,
  Label,
  Popover,
} from "react-aria-components";

import { calendarFor, isValidIsoDate } from "./formatters";
import { useLocale } from "./i18n_provider";

type DateFieldProps = {
  testId: string;
  label: string;
  value: string;
  min: string;
  max: string;
  onChange: (isoDate: string) => void;
  name?: string;
};

type SegmentView = {
  type: string;
  text: string;
  isPlaceholder: boolean;
};

function toCalendarDate(iso: string): CalendarDate | null {
  return isValidIsoDate(iso) ? parseDate(iso) : null;
}

function toIso(date: DateValue): string {
  return date instanceof CalendarDate
    ? toCalendar(date, new GregorianCalendar()).toString()
    : date.toString();
}

function calendarIdFor(locale: string): "buddhist" | "gregory" {
  return calendarFor(locale).includes("-u-ca-buddhist") ? "buddhist" : "gregory";
}

function segmentsToIso(
  segments: readonly SegmentView[] | undefined,
  calendarId: CalendarIdentifier,
): string | null {
  if (!segments) return null;

  const parts = new Map<string, number>();
  for (const segment of segments) {
    if (segment.isPlaceholder || !["year", "month", "day"].includes(segment.type)) continue;
    const digits = segment.text.replace(/[^\d-]/g, "");
    if (digits === "") return null;
    parts.set(segment.type, Number(digits));
  }

  const year = parts.get("year");
  const month = parts.get("month");
  const day = parts.get("day");
  if (year === undefined || month === undefined || day === undefined) return null;

  const display = new CalendarDate(createCalendar(calendarId), year, month, day);
  if (display.year !== year || display.month !== month || display.day !== day) return null;

  return toCalendar(display, new GregorianCalendar()).toString();
}

function DateFieldMonitor({
  calendarId,
  min,
  max,
  value,
  onChange,
  isoRef,
  invalidRef,
}: {
  calendarId: CalendarIdentifier;
  min: string;
  max: string;
  value: string;
  onChange: (isoDate: string) => void;
  isoRef: MutableRefObject<string | null>;
  invalidRef: MutableRefObject<boolean>;
}) {
  const state = useContext(DateFieldStateContext);
  const iso = segmentsToIso(state?.segments, calendarId);
  const complete = state?.segments.some((segment) => segment.isPlaceholder) === false;
  const valid = iso !== null && iso >= min && iso <= max;

  useEffect(() => {
    if (complete && !valid) invalidRef.current = true;
    isoRef.current = valid ? iso : null;
    if (!valid || iso === value) return;

    const timer = setTimeout(() => onChange(iso), 250);
    return () => clearTimeout(timer);
  }, [complete, invalidRef, iso, isoRef, onChange, valid, value]);

  return null;
}

export function DateField({ testId, label, value, min, max, onChange, name }: DateFieldProps) {
  if (!isValidIsoDate(min) || !isValidIsoDate(max) || min > max) {
    throw new Error("DateField requires valid ISO min and max dates");
  }

  const { locale } = useLocale();
  const calendarId = calendarIdFor(locale);
  const [draft, setDraft] = useState<CalendarDate | null>(() => toCalendarDate(value));
  const [resetKey, setResetKey] = useState(0);
  const isoRef = useRef<string | null>(null);
  const invalidRef = useRef(false);
  const forceResetRef = useRef(false);
  const lastValueRef = useRef(value);

  useEffect(() => {
    if (lastValueRef.current === value) return;

    lastValueRef.current = value;
    setDraft(toCalendarDate(value));
  }, [value]);

  function resetToValue() {
    forceResetRef.current = true;
    setDraft(toCalendarDate(value));
    setResetKey((key) => key + 1);
  }

  return (
    <DatePicker
      key={resetKey}
      aria-label={label}
      name={name}
      value={draft}
      minValue={toCalendarDate(min)}
      maxValue={toCalendarDate(max)}
      onChange={(date) => {
        if (forceResetRef.current) {
          forceResetRef.current = false;
          return;
        }

        setDraft(date ? toCalendarDate(toIso(date)) : null);
      }}
      onFocus={() => {
        invalidRef.current = false;
      }}
      onBlur={(event) => {
        if (event.currentTarget.contains(event.relatedTarget as Node | null)) return;

        if (invalidRef.current || isoRef.current === null) {
          resetToValue();
          return;
        }

        setDraft(toCalendarDate(isoRef.current));
        if (isoRef.current !== value) onChange(isoRef.current);
        invalidRef.current = false;
      }}
      className="block text-sm font-medium text-slate-700"
    >
      <Label>{label}</Label>
      <Group className="mt-1 flex items-center rounded border border-slate-300 px-3 py-2">
        <DateInput className="flex-1">
          {(segment) => (
            <>
              <DateSegment segment={segment} data-testid={`${testId}.${segment.type}`} />
              {segment.type === "day" ? (
                <DateFieldMonitor
                  calendarId={calendarId}
                  min={min}
                  max={max}
                  value={value}
                  onChange={onChange}
                  isoRef={isoRef}
                  invalidRef={invalidRef}
                />
              ) : null}
            </>
          )}
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
