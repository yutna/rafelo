import { useState } from "react";

import { isValidIsoDate } from "./formatters";
import { useLocale } from "./i18n_provider";

type DateFieldProps = {
  label: string;
  value: string;
  min: string;
  max: string;
  onChange: (isoDate: string) => void;
  locale?: string;
};

function toDisplay(iso: string, locale: string): string {
  if (!iso) return "";
  const [year, month, day] = iso.split("-").map(Number);
  return locale === "th" ? `${day}/${month}/${year + 543}` : iso;
}

function toIso(display: string, locale: string): string | null {
  if (locale !== "th") {
    return /^\d{4}-\d{2}-\d{2}$/.test(display) ? display : null;
  }
  const match = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(display);
  if (!match) return null;
  const day = Number(match[1]);
  const month = Number(match[2]);
  const year = Number(match[3]) - 543;
  const iso = `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
  return isValidIsoDate(iso) ? iso : null;
}

export function DateField({ label, value, min, max, onChange, locale }: DateFieldProps) {
  const context = useLocale();
  const activeLocale = locale ?? context.locale;
  const [text, setText] = useState(() => toDisplay(value, activeLocale));

  function commit(next: string) {
    setText(next);
    const iso = toIso(next, activeLocale);
    if (iso && iso >= min && iso <= max) onChange(iso);
  }

  return (
    <label className="block text-sm font-medium text-slate-700">
      {label}
      <input
        value={text}
        onChange={(event) => commit(event.target.value)}
        inputMode="numeric"
        aria-label={label}
        className="mt-1 w-full rounded border px-3 py-2"
      />
    </label>
  );
}
