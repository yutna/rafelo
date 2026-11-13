export function isSafeUrl(value: unknown): value is string {
  if (typeof value !== "string" || value.length === 0) return false;
  if (value !== value.trim()) return false;
  if (/[\\\u0000-\u001f\u007f]/.test(value)) return false;

  if (value.startsWith("/")) return value.startsWith("/") && !value.startsWith("//");

  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:";
  } catch {
    return false;
  }
}

export function isAppPath(value: unknown): value is string {
  return typeof value === "string" && value.startsWith("/") && !value.startsWith("//") && !/[\\\u0000-\u001f\u007f]/.test(value);
}
