import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { basename, dirname, join, relative, resolve } from "node:path";
import { parseDocument } from "yaml";

const rootArg = process.argv.indexOf("--root");
const root = rootArg >= 0 ? resolve(process.argv[rootArg + 1]) : process.cwd();
const check = process.argv.includes("--check");
if (!existsSync(root)) {
  console.error(`i18n: root does not exist: ${root}`);
  process.exit(1);
}
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

function transformString(value: string, path: string): string {
  if (value.trim() === "") fail(`${path} is blank`);
  if (value.includes("{{") || value.includes("$t(") || /%<[^>]+>s/.test(value)) {
    fail(`${path} contains an unsupported interpolation`);
  }
  const literal = value.replace(/%%\{(\w+)\}/g, "\u0000L$1\u0000");
  const interpolated = literal.replace(/%\{(\w+)\}/g, "{{$1}}");
  return interpolated.replace(/\u0000L(\w+)\u0000/g, "%{$1}");
}

function isPlural(value: unknown): boolean {
  return Boolean(
    value &&
      typeof value === "object" &&
      !Array.isArray(value) &&
      Object.keys(value as Record<string, unknown>).length > 0 &&
      Object.keys(value as Record<string, unknown>).every((key) => pluralKeys.has(key)),
  );
}

function transformObject(value: Record<string, unknown>, path: string): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, entry] of Object.entries(value)) {
    if (isPlural(entry)) {
      const categories = entry as Record<string, unknown>;
      if (!("one" in categories) || !("other" in categories)) {
        fail(`${path}.${key} plural is missing one or other`);
      }
      for (const [category, text] of Object.entries(categories)) {
        if (typeof text !== "string") {
          fail(`${path}.${key}.${category} nested plural is not supported`);
        }
        result[`${key}_${category}`] = transformString(text, `${path}.${key}.${category}`);
      }
    } else if (typeof entry === "string") {
      result[key] = transformString(entry, `${path}.${key}`);
    } else if (entry && typeof entry === "object" && !Array.isArray(entry)) {
      result[key] = transformObject(entry as Record<string, unknown>, `${path}.${key}`);
    } else {
      fail(`${path}.${key} is blank or unsupported`);
    }
  }
  return result;
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
  catalogs.push({ path, namespace, locale, data: transformObject(data as Record<string, unknown>, namespace) });
}

for (const locale of locales) {
  const path = join(root, "config/locales", `${locale}.yml`);
  if (!existsSync(path)) fail(`missing root ${locale} catalog`);
  readCatalog(path, "app");
  for (const engine of engines) {
    const enginePath = join(root, "engines", engine, "config/locales", `${locale}.yml`);
    if (!existsSync(enginePath)) fail(`missing ${relative(root, enginePath)}`);
    readCatalog(enginePath, engine);
  }
}

if (catalogs.length === 0) fail("no catalogs found");

const groups = new Map<string, Catalog[]>();
for (const catalog of catalogs) {
  groups.set(catalog.namespace, [...(groups.get(catalog.namespace) ?? []), catalog]);
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

const generated = new Set<string>();
function write(path: string, content: string) {
  generated.add(path);
  if (check) {
    let current = "";
    try {
      current = readFileSync(path, "utf8");
    } catch {
      fail(`${relative(root, path)} is missing`);
    }
    if (current !== content) fail(`${relative(root, path)} is stale`);
    return;
  }
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}

for (const catalog of catalogs) {
  const target =
    catalog.namespace === "app"
      ? join(root, "app/frontend/locales", `${catalog.locale}.json`)
      : join(root, "engines", catalog.namespace, "app/frontend/locales", `${catalog.locale}.json`);
  write(target, `${JSON.stringify(catalog.data, null, 2)}\n`);
}

const localesFile = join(root, "engines/core/app/frontend/contracts/locales.generated.ts");
write(
  localesFile,
  `// Generated from config/locales.yml; do not edit.\nimport { z } from "zod";\n\nexport const localeSchema = z.enum(${JSON.stringify(locales)} as const);\nexport type Locale = z.infer<typeof localeSchema>;\nexport const defaultLocale: Locale = ${JSON.stringify(localesConfig.default)};\n`,
);

const existingApps = readdirSync(join(root, "app/frontend/locales"), { withFileTypes: true })
  .filter((entry) => entry.isFile() && entry.name.endsWith(".json"))
  .map((entry) => join(root, "app/frontend/locales", entry.name));
const existingEngines = engines.flatMap((engine) => {
  const dir = join(root, "engines", engine, "app/frontend/locales");
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.endsWith(".json"))
    .map((entry) => join(dir, entry.name));
});
for (const path of [...existingApps, ...existingEngines]) {
  if (!generated.has(path)) fail(`${relative(root, path)} has no source catalog`);
}

console.log(`i18n: ${check ? "checked" : "generated"} ${catalogs.length} catalog(s) for ${locales.join(", ")}`);
