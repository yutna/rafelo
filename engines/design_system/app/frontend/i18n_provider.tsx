import type { ReactNode } from "react";

import { createContext, useContext } from "react";
import { I18nProvider as AriaI18nProvider } from "react-aria-components";

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

export function I18nProvider({
  locale,
  timeZone,
  children,
}: {
  locale: string;
  timeZone: string;
  children: ReactNode;
}) {
  const calendar = calendarFor(locale);

  return (
    <AriaI18nProvider locale={calendar}>
      <LocaleContext.Provider value={{ locale, calendar, timeZone }}>
        {children}
      </LocaleContext.Provider>
    </AriaI18nProvider>
  );
}

export function useLocale(): LocaleContextValue {
  return useContext(LocaleContext);
}
