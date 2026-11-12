import { describe, expect, it } from "vitest";

import { setLocale, t } from "./i18n";

describe("i18n", () => {
  it("switches from English to Thai", async () => {
    await setLocale("en");
    expect(t("app:home.message")).toBe("Rafelo");

    await setLocale("th");
    expect(t("app:home.message")).toBe("ราฟีโล");
    expect(t("design_system:nav.title")).toBe("ระบบออกแบบ");
  });
});
