import i18next from "i18next";

import enApp from "../locales/en.json";
import thApp from "../locales/th.json";
import enCore from "@core/locales/en.json";
import thCore from "@core/locales/th.json";
import enDesignSystem from "@design_system/locales/en.json";
import thDesignSystem from "@design_system/locales/th.json";

const initialized = i18next.init({
  resources: {
    en: { app: enApp, core: enCore, design_system: enDesignSystem },
    th: { app: thApp, core: thCore, design_system: thDesignSystem },
  },
  lng: "en",
  fallbackLng: "en",
  interpolation: { escapeValue: false },
});

export async function setLocale(locale: string): Promise<void> {
  await initialized;
  await i18next.changeLanguage(locale);
}

export function t(key: string): string {
  const [namespace, ...rest] = key.split(":");
  return rest.length > 0 ? i18next.t(rest.join(":"), { ns: namespace }) : i18next.t(key);
}
