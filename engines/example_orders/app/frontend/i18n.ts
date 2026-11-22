import i18next from "i18next";

export function useOrdersTranslation() {
  return (key: string, options?: Record<string, unknown>): string =>
    i18next.t(key, { ns: "example_orders", ...options });
}
