const THAI_CALENDAR = "th-TH-u-ca-buddhist";

export function calendarFor(locale: string): string {
  return locale === "th" ? THAI_CALENDAR : `${locale}-u-ca-gregory`;
}

export function formatDate(value: string | Date, locale: string, timeZone = "UTC"): string {
  const date = typeof value === "string" ? new Date(value) : value;
  return new Intl.DateTimeFormat(calendarFor(locale), {
    dateStyle: "medium",
    timeZone,
  }).format(date);
}

export function formatNumber(value: number, locale: string): string {
  return new Intl.NumberFormat(locale).format(value);
}
