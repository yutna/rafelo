export const first = "first";
export const second = "second";

export function label(value: string): string {
  const trimmed = value.trim();
  return `${trimmed}:${first}:${second}`;
}

export function shout(value: string): string {
  const trimmed = value.trim();
  return `${trimmed}:${first}:${second}`.toUpperCase();
}
