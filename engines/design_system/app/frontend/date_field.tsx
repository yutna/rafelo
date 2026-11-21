import type { CalendarIdentifier, DateValue } from "@internationalized/date";
import type { MutableRefObject } from "react";

import {
  CalendarDate,
  GregorianCalendar,
  createCalendar,
  parseDate,
  toCalendar,
} from "@internationalized/date";
import { useContext, useEffect, useMemo, useRef, useState } from "react";
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
  isoRef,
  invalidRef,
}: {
  calendarId: CalendarIdentifier;
  min: string;
  max: string;
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
  }, [complete, invalidRef, iso, isoRef, valid]);

  return null;
}

export function DateField({ testId, label, value, min, max, onChange, name }: DateFieldProps) {
  if (!isValidIsoDate(min) || !isValidIsoDate(max) || min > max) {
    throw new Error("DateField requires valid ISO min and max dates");
  }

  const { locale } = useLocale();
  const calendarId = calendarIdFor(locale);
  const [draft, setDraft] = useState({ iso: value });
  const draftDate = useMemo(() => toCalendarDate(draft.iso), [draft]);
  const isoRef = useRef<string | null>(null);
  const invalidRef = useRef(false);
  const focusedRef = useRef(false);
  const openRef = useRef(false);
  const suppressChangeRef = useRef(false);
  const lastValueRef = useRef(value);

  useEffect(() => {
    if (lastValueRef.current === value) return;

    lastValueRef.current = value;
    setDraft({ iso: value });
  }, [value]);

  function resetToValue(nextFocus: HTMLElement | null) {
    suppressChangeRef.current = true;
    setDraft({ iso: value });
    if (nextFocus && document.contains(nextFocus)) setTimeout(() => nextFocus.focus(), 0);
  }

  function commit(): boolean {
    if (invalidRef.current || isoRef.current === null) {
      resetToValue(null);
      return false;
    }

    const iso = isoRef.current;
    setDraft({ iso });
    if (iso !== value) onChange(iso);
    invalidRef.current = false;
    return true;
  }

  return (
    <DatePicker
      aria-label={label}
      name={name}
      value={draftDate}
      minValue={toCalendarDate(min)}
      maxValue={toCalendarDate(max)}
      onChange={(date) => {
        if (suppressChangeRef.current) return;

        const iso = date ? toIso(date) : "";
        setDraft({ iso });
        if ((openRef.current || !focusedRef.current) && iso !== "" && iso >= min && iso <= max) {
          onChange(iso);
        }
      }}
      onOpenChange={(open) => {
        openRef.current = open;
      }}
      onFocus={() => {
        focusedRef.current = true;
        suppressChangeRef.current = false;
        invalidRef.current = false;
      }}
      onBlur={(event) => {
        const next = event.relatedTarget as HTMLElement | null;
        if (event.currentTarget.contains(next)) return;

        focusedRef.current = false;
        if (openRef.current) return;
        if (invalidRef.current || isoRef.current === null) {
          resetToValue(next);
          return;
        }

        commit();
      }}
      onKeyDown={(event) => {
        if (event.key === "Enter") commit();
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
                  isoRef={isoRef}
                  invalidRef={invalidRef}
                />
              ) : null}
            </>
          )}
        </DateInput>
        <AriaButton
          className="ml-2 text-slate-600"
          aria-label={label}
          data-testid={`${testId}.calendar`}
        >
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
            <CalendarGrid>
              {(date) => (
                <CalendarCell date={date} data-testid={`${testId}.calendar.${date.toString()}`} />
              )}
            </CalendarGrid>
          </Calendar>
        </Dialog>
      </Popover>
    </DatePicker>
  );
}
