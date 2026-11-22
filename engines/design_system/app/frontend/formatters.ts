const THAI_CALENDAR = "th-TH-u-ca-buddhist";
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

export function calendarFor(locale: string): string {
  return locale === "th" ? THAI_CALENDAR : `${locale}-u-ca-gregory`;
}

export function formatDate(value: string | Date, locale: string, timeZone = "UTC"): string {
  const calendarDate = typeof value === "string" && ISO_DATE.test(value);
  const date = calendarDate ? new Date(`${value}T00:00:00Z`) : new Date(value);

  return new Intl.DateTimeFormat(calendarFor(locale), {
    dateStyle: "medium",
    timeZone: calendarDate ? "UTC" : timeZone,
  }).format(date);
}

export function formatDateTime(value: string | Date, locale: string, timeZone = "UTC"): string {
  return new Intl.DateTimeFormat(calendarFor(locale), {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone,
  }).format(new Date(value));
}

export function formatNumber(value: number, locale: string): string {
  return new Intl.NumberFormat(locale).format(value);
}

export function isValidIsoDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [year, month, day] = value.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return (
    date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day
  );
}

export function formatMoney(
  minor: number,
  currency: string,
  exponent: number,
  locale: string,
): string {
  const amount = minor / 10 ** exponent;
  return `${new Intl.NumberFormat(locale, { minimumFractionDigits: exponent, maximumFractionDigits: exponent }).format(amount)} ${currency}`;
}
