import i18next from "i18next";

export function t(key: string, options?: Record<string, unknown>): string {
  return i18next.t(key, { ns: "design_system", ...options });
}
