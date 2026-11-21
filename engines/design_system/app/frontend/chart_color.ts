import type { ChartTheme } from "./chart.types";

const TOKEN_FALLBACKS: Record<string, string> = {
  "--color-primary": "#4f39f6",
  "--color-primary-hover": "#4338ca",
  "--color-danger": "#be123c",
  "--color-success": "#059669",
  "--color-muted-foreground": "#475569",
  "--color-surface": "#ffffff",
};

const THEME_TOKENS = [
  "--color-primary",
  "--color-primary-hover",
  "--color-danger",
  "--color-success",
  "--color-muted-foreground",
];

type StyleSource = Pick<CSSStyleDeclaration, "getPropertyValue">;

function channel(value: number): number {
  const clamped = Math.min(1, Math.max(0, value));
  const encoded = clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * clamped ** (1 / 2.4) - 0.055;
  return Math.round(encoded * 255);
}

function hex(red: number, green: number, blue: number): string {
  return `#${[red, green, blue].map((value) => channel(value).toString(16).padStart(2, "0")).join("")}`;
}

export function toSrgbHex(input: string): string {
  const value = input.trim().toLowerCase();
  const shortHex = value.match(/^#([0-9a-f])([0-9a-f])([0-9a-f])$/);
  if (shortHex)
    return `#${shortHex[1]}${shortHex[1]}${shortHex[2]}${shortHex[2]}${shortHex[3]}${shortHex[3]}`;
  if (/^#[0-9a-f]{6}$/.test(value)) return value;

  const match = value.match(/^oklch\(\s*([\d.]+)(%?)\s+([\d.]+)\s+([\d.]+)(?:deg)?\s*\)$/);
  if (!match) throw new Error(`Unsupported chart color: ${input}`);

  const lightness = match[2] === "%" ? Number(match[1]) / 100 : Number(match[1]);
  const chroma = Number(match[3]);
  const hue = (Number(match[4]) * Math.PI) / 180;
  const a = chroma * Math.cos(hue);
  const b = chroma * Math.sin(hue);

  const l = (lightness + 0.3963377774 * a + 0.2158037573 * b) ** 3;
  const m = (lightness - 0.1055613458 * a - 0.0638541728 * b) ** 3;
  const s = (lightness - 0.0894841775 * a - 1.291485548 * b) ** 3;

  return hex(
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
  );
}

function tokenValue(styles: StyleSource, token: string): string {
  const value = styles.getPropertyValue(token).trim();
  if (!value) return TOKEN_FALLBACKS[token] ?? "#000000";
  const reference = value.match(/^var\(\s*(--[a-z0-9-]+)\s*\)$/i);
  if (!reference) return value;
  return styles.getPropertyValue(reference[1]).trim() || TOKEN_FALLBACKS[token] || "#000000";
}

export function chartTheme(styles: StyleSource): ChartTheme {
  return {
    color: THEME_TOKENS.map((token) => toSrgbHex(tokenValue(styles, token))),
    backgroundColor: toSrgbHex(tokenValue(styles, "--color-surface")),
    textStyle: { color: toSrgbHex(tokenValue(styles, "--color-muted-foreground")) },
  };
}
