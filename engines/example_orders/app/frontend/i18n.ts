import i18next from "i18next";

import en from "./locales/en.json";
import th from "./locales/th.json";

i18next.addResourceBundle("en", "example_orders", en, true, true);
i18next.addResourceBundle("th", "example_orders", th, true, true);

export function t(key: string): string {
  return i18next.t(key, { ns: "example_orders" });
}
