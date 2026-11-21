import { describe, expect, it } from "vitest";

import { chartTheme, toSrgbHex } from "./chart_color";

const tokens: Record<string, string> = {
  "--color-primary": "oklch(0.511 0.262 276.966)",
  "--color-primary-hover": "oklch(0.457 0.24 277.023)",
  "--color-danger": "oklch(0.505 0.213 27.518)",
  "--color-success": "oklch(0.596 0.145 163.225)",
  "--color-muted-foreground": "oklch(0.446 0.043 257.281)",
  "--color-surface": "oklch(1 0 0)",
  "--color-indigo-600": "oklch(0.511 0.262 276.966)",
};

const styles = {
  getPropertyValue: (token: string) => tokens[token] ?? "",
};

describe("chart colors", () => {
  it("converts Tailwind's oklch tokens to sRGB hex", () => {
    expect(toSrgbHex("oklch(0.511 0.262 276.966)")).toBe("#4f39f6");
    expect(toSrgbHex("oklch(51.1% 0.262 276.966)")).toBe("#4f39f6");
  });

  it("keeps a color that is already hex", () => {
    expect(toSrgbHex("#4F39F6")).toBe("#4f39f6");
    expect(toSrgbHex("#fff")).toBe("#ffffff");
  });

  it("resolves a token that points at another custom property", () => {
    const indirect = {
      getPropertyValue: (token: string) =>
        token === "--color-primary" ? "var(--color-indigo-600)" : (tokens[token] ?? ""),
    };

    expect(chartTheme(indirect).color[0]).toBe("#4f39f6");
  });

  it("builds a theme where every color is a non-empty sRGB hex", () => {
    const theme = chartTheme(styles);

    expect(theme.color).toHaveLength(5);
    for (const color of theme.color) {
      expect(color).toMatch(/^#[0-9a-f]{6}$/);
    }
    expect(theme.backgroundColor).toMatch(/^#[0-9a-f]{6}$/);
    expect(theme.textStyle.color).toMatch(/^#[0-9a-f]{6}$/);
  });

  it("falls back to the known token hex when a computed value is empty", () => {
    const theme = chartTheme({ getPropertyValue: () => "" });

    expect(theme.color[0]).toBe("#4f39f6");
  });

  it("rejects a color syntax ECharts cannot read", () => {
    expect(() => toSrgbHex("color(display-p3 1 0 0)")).toThrow(/Unsupported chart color/);
  });
});
