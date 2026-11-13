import { useLocale } from "@design_system/public";

import en from "./locales/en.json";
import th from "./locales/th.json";

const catalogs = { en, th } as const;

export function useOrdersTranslation() {
  const { locale } = useLocale();
  const catalog = catalogs[locale as keyof typeof catalogs] ?? catalogs.en;

  return (key: string): string => {
    const value = key.split(".").reduce<unknown>((current, part) => {
      if (!current || typeof current !== "object") return undefined;
      return (current as Record<string, unknown>)[part];
    }, catalog);
    return typeof value === "string" ? value : key;
  };
}
