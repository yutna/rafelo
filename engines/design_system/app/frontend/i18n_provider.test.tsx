import { render, screen } from "@testing-library/react";
import { useLocale } from "react-aria-components";
import { describe, expect, it } from "vitest";

import { I18nProvider } from "./i18n_provider";

function AriaLocaleProbe() {
  const { locale } = useLocale();
  return <span data-testid="aria.locale">{locale}</span>;
}

describe("I18nProvider", () => {
  it("sets React Aria's locale to the Buddhist calendar for Thai", () => {
    render(
      <I18nProvider locale="th" timeZone="Asia/Bangkok">
        <AriaLocaleProbe />
      </I18nProvider>,
    );

    expect(screen.getByTestId("aria.locale")).toHaveTextContent("th-TH-u-ca-buddhist");
  });

  it("sets React Aria's locale to the Gregorian calendar for English", () => {
    render(
      <I18nProvider locale="en" timeZone="UTC">
        <AriaLocaleProbe />
      </I18nProvider>,
    );

    expect(screen.getByTestId("aria.locale")).toHaveTextContent("en-u-ca-gregory");
  });
});
