import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { basename, dirname, join, relative, resolve } from "node:path";
import { parseDocument } from "yaml";

const root = process.cwd();
const check = process.argv.includes("--check");
const localesConfig = parseDocument(readFileSync(join(root, "config/locales.yml"), "utf8")).toJS() as {
  available: string[];
  default: string;
};
const locales = localesConfig.available;
const engines = readdirSync(join(root, "engines"), { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

type Catalog = { path: string; namespace: string; locale: string; data: Record<string, unknown> };
const catalogs: Catalog[] = [];
const pluralKeys = new Set(["zero", "one", "two", "few", "many", "other"]);

function fail(message: string): never {
  console.error(`i18n: ${message}`);
  process.exit(1);
}

function transform(value: unknown, path: string): unknown {
  if (typeof value === "string") {
    if (value.includes("{{") || value.includes("$t(") || /%<[^>]+>s/.test(value)) {
      fail(`${path} contains an unsupported interpolation`);
    }
    return value.replace(/%%\{(\w+)\}/g, "%{$1}").replace(/%\{(\w+)\}/g, "{{$1}}");
  }
  if (value === null || value === undefined || (typeof value === "string" && value.trim() === "")) {
    fail(`${path} is blank`);
  }
  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>);
    const keys = entries.map(([key]) => key);
    if (keys.every((key) => pluralKeys.has(key))) {
      if (!keys.includes("one") || !keys.includes("other")) {
        fail(`${path} plural is missing one or other`);
      }
      const transformed: Record<string, unknown> = {};
      for (const [key, entry] of entries) {
        if (typeof entry !== "string") {
          fail(`${path}.${key} nested plural is not supported`);
        }
        transformed[`${path.split(".").pop()}_${key}`] = transform(entry, `${path}.${key}`);
      }
      return transformed;
    }
    const transformed: Record<string, unknown> = {};
    for (const [key, entry] of entries) {
      transformed[key] = transform(entry, `${path}.${key}`);
    }
    return transformed;
  }
  return value;
}

function readCatalog(path: string, namespace: string) {
  const text = readFileSync(path, "utf8");
  const document = parseDocument(text);
  if (document.errors.length > 0) {
    fail(`${relative(root, path)} is not valid YAML: ${document.errors[0].message}`);
  }
  const raw = (document.toJS() ?? {}) as Record<string, Record<string, unknown>>;
  const locale = basename(path, ".yml");
  if (Object.keys(raw).length !== 1 || !raw[locale]) {
    fail(`${relative(root, path)} must hold exactly the ${locale} top-level key`);
  }
  const localeData = raw[locale] as Record<string, unknown>;
  if (namespace !== "app" && Object.keys(localeData).some((key) => key !== namespace)) {
    fail(`${relative(root, path)} may only hold the ${namespace} namespace`);
  }
  const data = namespace === "app" ? localeData.app : localeData[namespace];
  if (!data || typeof data !== "object") {
    fail(`${relative(root, path)} is missing the ${namespace} namespace`);
  }
  catalogs.push({ path, namespace, locale, data: transform(data, namespace) as Record<string, unknown> });
}

for (const locale of locales) {
  const path = join(root, "config/locales", `${locale}.yml`);
  if (!existsSync(path)) fail(`missing root ${locale} catalog`);
  readCatalog(path, "app");
  for (const engine of engines) {
    const enginePath = join(root, "engines", engine, "config/locales", `${locale}.yml`);
    if (existsSync(enginePath)) readCatalog(enginePath, engine);
  }
}

if (catalogs.length === 0) fail("no catalogs found");

const groups = new Map<string, Catalog[]>();
for (const catalog of catalogs) {
  const key = catalog.namespace;
  groups.set(key, [...(groups.get(key) ?? []), catalog]);
}

function keyPaths(value: unknown, prefix = ""): string[] {
  if (value === null || typeof value !== "object") return [prefix];
  return Object.entries(value as Record<string, unknown>).flatMap(([key, entry]) =>
    keyPaths(entry, prefix ? `${prefix}.${key}` : key),
  );
}

for (const [namespace, group] of groups) {
  const reference = group[0];
  const referenceKeys = keyPaths(reference.data).sort();
  for (const catalog of group) {
    const keys = keyPaths(catalog.data).sort();
    if (JSON.stringify(keys) !== JSON.stringify(referenceKeys)) {
      fail(`${catalog.path} does not match ${reference.path} for ${namespace}`);
    }
  }
}

for (const catalog of catalogs) {
  const target =
    catalog.namespace === "app"
      ? join(root, "app/frontend/locales", `${catalog.locale}.json`)
      : join(root, "engines", catalog.namespace, "app/frontend/locales", `${catalog.locale}.json`);
  const content = `${JSON.stringify(catalog.data, null, 2)}\n`;
  if (check) {
    let current = "";
    try {
      current = readFileSync(target, "utf8");
    } catch {
      fail(`${relative(root, target)} is missing`);
    }
    if (current !== content) fail(`${relative(root, target)} is stale`);
  } else {
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, content);
  }
}

console.log(`i18n: ${check ? "checked" : "generated"} ${catalogs.length} catalog(s) for ${locales.join(", ")}`);
