import { createContext, useContext } from "react";
import type { ReactNode } from "react";

import { calendarFor } from "./formatters";

type LocaleContextValue = {
  locale: string;
  calendar: string;
  timeZone: string;
};

const LocaleContext = createContext<LocaleContextValue>({
  locale: "en",
  calendar: calendarFor("en"),
  timeZone: "UTC",
});

export function I18nProvider({ locale, timeZone, children }: { locale: string; timeZone: string; children: ReactNode }) {
  return (
    <LocaleContext.Provider value={{ locale, calendar: calendarFor(locale), timeZone }}>
      {children}
    </LocaleContext.Provider>
  );
}

export function useLocale(): LocaleContextValue {
  return useContext(LocaleContext);
}
