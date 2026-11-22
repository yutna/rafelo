import i18next from "i18next";

export function useOrdersTranslation() {
  return (key: string): string => i18next.t(key, { ns: "example_orders" });
}
