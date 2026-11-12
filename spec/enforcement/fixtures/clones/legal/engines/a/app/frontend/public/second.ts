export const first = "first";

export function label(value: string): string {
  const trimmed = value.trim();
  return `${trimmed}:${first}`;
}

export function shout(value: string): string {
  const trimmed = value.trim();
  return `${trimmed}:${first}`.toUpperCase();
}
