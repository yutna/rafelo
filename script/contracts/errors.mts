import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { parseDocument } from "yaml";

const rootArg = process.argv.indexOf("--root");
const root = rootArg >= 0 ? resolve(process.argv[rootArg + 1]) : process.cwd();
const check = process.argv.includes("--check");
if (!existsSync(root) || !existsSync(join(root, "engines"))) {
  console.error(`errors: root does not exist: ${root}`);
  process.exit(1);
}
const codePattern = /^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$/;
const entryKeys = new Set(["status", "i18n_key", "retryable"]);
const engines = readdirSync(join(root, "engines"), { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

type Catalog = { path: string; engine: string | null; codes: Record<string, Record<string, unknown>> };
const catalogs: Catalog[] = [];

function fail(message: string): never {
  console.error(`errors: ${message}`);
  process.exit(1);
}

function readCatalog(path: string, engine: string | null) {
  const text = readFileSync(path, "utf8");
  const document = parseDocument(text);
  if (document.errors.length > 0) {
    fail(`${relative(root, path)} is not valid YAML: ${document.errors[0].message}`);
  }
  const data = (document.toJS() ?? {}) as Record<string, Record<string, unknown>>;
  for (const code of Object.keys(data)) {
    if (!codePattern.test(code)) {
      fail(`${relative(root, path)}: ${code} is not a valid code`);
    }
    if (engine && !code.startsWith(`${engine}.`)) {
      fail(`${relative(root, path)}: ${code} must start with ${engine}.`);
    }
    if (!engine && engines.some((name) => code.startsWith(`${name}.`))) {
      fail(`${relative(root, path)}: ${code} belongs to an engine catalog`);
    }
    const entry: any = data[code];
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) {
      fail(`${relative(root, path)}: ${code} must map to an entry`);
    }
    const keys = Object.keys(entry).sort();
    if (JSON.stringify(keys) !== JSON.stringify([...entryKeys].sort())) {
      fail(`${relative(root, path)}: ${code} has keys ${keys.join(", ")}`);
    }
    if (!Number.isInteger(entry.status) || entry.status < 400 || entry.status > 599) {
      fail(`${relative(root, path)}: ${code}.status must be an integer 400..599`);
    }
    if (typeof entry.i18n_key !== "string" || entry.i18n_key.trim() === "") {
      fail(`${relative(root, path)}: ${code}.i18n_key must be a non-empty string`);
    }
    if (typeof entry.retryable !== "boolean") {
      fail(`${relative(root, path)}: ${code}.retryable must be boolean`);
    }
  }
  catalogs.push({ path, engine, codes: data });
}

readCatalog(join(root, "config/errors.yml"), null);
for (const engine of engines) {
  const path = join(root, "engines", engine, "config/errors.yml");
  if (existsSync(path)) {
    readCatalog(path, engine);
  }
}

const seen = new Map<string, string>();
for (const catalog of catalogs) {
  for (const code of Object.keys(catalog.codes)) {
    if (seen.has(code)) {
      fail(`${code} is defined in ${relative(root, seen.get(code)!)} and ${relative(root, catalog.path)}`);
    }
    seen.set(code, catalog.path);
  }
}

if (catalogs.length === 0) {
  fail("no error catalogs found");
}

const groups = new Map<string, Catalog>();
for (const catalog of catalogs) {
  const key = catalog.engine ?? "core";
  groups.set(key, { ...catalog, codes: { ...(groups.get(key)?.codes ?? {}), ...catalog.codes } });
}

for (const [engine, catalog] of groups) {
  const target = join(root, "engines", engine, "app", "frontend", "errors.generated.ts");
  const entries = Object.entries(catalog.codes)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([code, entry]) => `  ${JSON.stringify(code)}: { status: ${entry.status}, retryable: ${entry.retryable} },`)
    .join("\n");
  const content = `// Generated from config/errors.yml; do not edit.\nexport const errors = {\n${entries}\n} as const;\n`;
  if (check) {
    let current = "";
    try {
      current = readFileSync(target, "utf8");
    } catch {
      fail(`${relative(root, target)} is missing`);
    }
    if (current !== content) {
      fail(`${relative(root, target)} is stale`);
    }
  } else {
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, content);
  }
}

for (const engine of engines) {
  const path = join(root, "engines", engine, "app", "frontend", "errors.generated.ts");
  if (existsSync(path) && !groups.has(engine)) {
    fail(`${relative(root, path)} has no error catalog`);
  }
}

console.log(`errors: ${check ? "checked" : "generated"} ${catalogs.length} catalog(s), ${seen.size} code(s)`);
