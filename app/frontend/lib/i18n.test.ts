import enCore from "@core/locales/en.json";
import thCore from "@core/locales/th.json";
import enDesignSystem from "@design_system/locales/en.json";
import thDesignSystem from "@design_system/locales/th.json";
import { describe, expect, it } from "vitest";

import enApp from "@/locales/en.json";
import thApp from "@/locales/th.json";

import { loadNamespaces, t, type CatalogLoader } from "./i18n";

const catalogs = new Map<string, CatalogLoader>();

function catalog(namespace: string, locale: string, value: Record<string, unknown>) {
  catalogs.set(`${namespace}:${locale}`, async () => ({ default: value }));
}

catalog("app", "en", enApp);
catalog("app", "th", thApp);
catalog("core", "en", enCore);
catalog("core", "th", thCore);
catalog("design_system", "en", enDesignSystem);
catalog("design_system", "th", thDesignSystem);

describe("i18n", () => {
  it("loads every namespace before switching from English to Thai", async () => {
    await loadNamespaces(["app", "core", "design_system"], "en", catalogs);
    expect(t("app:home.message")).toBe("Rafelo");

    await loadNamespaces(["app", "core", "design_system"], "th", catalogs);
    expect(t("app:home.message")).toBe("ราฟีโล");
    expect(t("design_system:nav.title")).toBe("ระบบออกแบบ");
  });

  it("keeps a namespace and locale it already loaded", async () => {
    await loadNamespaces(["app"], "en", catalogs);

    const reloaded = new Map<string, CatalogLoader>([
      [
        "app:en",
        async () => {
          throw new Error("reloaded a cached catalog");
        },
      ],
    ]);

    await expect(loadNamespaces(["app"], "en", reloaded)).resolves.toBeUndefined();
  });

  it("fails when a page needs a catalog that is not there", async () => {
    await expect(loadNamespaces(["missing"], "en", catalogs)).rejects.toThrow(
      "Missing missing catalog for en",
    );
  });
});
