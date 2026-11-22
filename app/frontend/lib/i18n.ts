import i18next from "i18next";

type Catalog = { default: Record<string, unknown> };
export type CatalogLoader = () => Promise<Catalog>;

let initialized: Promise<unknown> | undefined;

function initialize(): Promise<unknown> {
  initialized ??= i18next.init({
    lng: "en",
    fallbackLng: "en",
    interpolation: { escapeValue: false },
  });
  return initialized;
}

export async function loadNamespaces(
  namespaces: readonly string[],
  locale: string,
  loaders: ReadonlyMap<string, CatalogLoader>,
): Promise<void> {
  await initialize();

  await Promise.all(
    namespaces.map(async (namespace) => {
      if (i18next.hasResourceBundle(locale, namespace)) return;
      const load = loaders.get(`${namespace}:${locale}`);
      if (!load) throw new Error(`Missing ${namespace} catalog for ${locale}`);

      const catalog = await load();
      i18next.addResourceBundle(locale, namespace, catalog.default, true, true);
    }),
  );

  await i18next.changeLanguage(locale);
}

export function t(key: string): string {
  const [namespace, ...rest] = key.split(":");
  return rest.length > 0 ? i18next.t(rest.join(":"), { ns: namespace }) : i18next.t(key);
}
