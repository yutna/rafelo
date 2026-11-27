// Fails when the resolved ESLint config sets parserOptions.project: type-aware
// rules may run only through projectService, so lint stays affected-only
// (09_enforcement.md, TS-07). `npm run lint` runs this before ESLint.
//
// One config is checked per scope (root, app, each engine, script, e2e, and a
// test file), with every directory traversed in byte order, so a path-scoped
// override cannot hide behind whatever `readdir` returned first. A file the
// config ignores answers no config and the scope moves to its next file.
import { spawnSync } from "node:child_process";
import { existsSync, readdirSync } from "node:fs";
import { join, relative, resolve } from "node:path";

const scriptRoot = resolve(import.meta.dirname, "../../..");
const CONFIG_NAMES = [
  "eslint.config.mjs",
  "eslint.config.js",
  "eslint.config.cjs",
  "eslint.config.mts",
];
const SKIP_DIRECTORIES = new Set([
  ".git",
  "node_modules",
  "public",
  "tmp",
  "vendor",
  "coverage",
  "test-results",
  "playwright-report",
]);
const SOURCE_FILE = /\.(?:ts|tsx|mts|cts)$/;
const TEST_FILE = /\.test\.(?:ts|tsx|mts|cts)$/;
// A config that ignores a whole scope would otherwise cost one ESLint start
// per file; five candidates prove a scope is lintable or leave it out.
const SCOPE_ATTEMPTS = 5;

function fail(message) {
  console.error(`eslint_config: ${message}`);
  process.exit(1);
}

let root = process.cwd();
let configPath = null;
let filePath = null;

const args = process.argv.slice(2);
for (let index = 0; index < args.length; index += 1) {
  const arg = args[index];
  if (arg === "--root") root = args[++index];
  else if (arg === "--config") configPath = args[++index];
  else if (arg === "--file") filePath = args[++index];
  else fail(`unknown argument ${arg}`);
}

root = resolve(root);
if (!existsSync(root)) fail(`root does not exist: ${root}; checked 0`);

function sortedEntries(directory) {
  return readdirSync(directory, { withFileTypes: true }).sort((left, right) =>
    left.name < right.name ? -1 : left.name > right.name ? 1 : 0,
  );
}

function sourceFiles(directory, predicate = () => true) {
  const files = [];
  if (!existsSync(directory)) return files;
  for (const entry of sortedEntries(directory)) {
    if (entry.isDirectory()) {
      if (SKIP_DIRECTORIES.has(entry.name)) continue;
      files.push(...sourceFiles(join(directory, entry.name), predicate));
    } else if (SOURCE_FILE.test(entry.name) && predicate(entry.name)) {
      files.push(join(directory, entry.name));
    }
  }
  return files;
}

function configScopes() {
  const scopes = [];
  const addScope = (files) => {
    if (files.length > 0) scopes.push(files);
  };

  addScope(
    sortedEntries(root)
      .filter((entry) => entry.isFile() && SOURCE_FILE.test(entry.name))
      .map((entry) => join(root, entry.name)),
  );
  for (const directory of ["app", "e2e", "script"]) {
    addScope(sourceFiles(join(root, directory)));
  }

  const engines = join(root, "engines");
  if (existsSync(engines)) {
    for (const engine of sortedEntries(engines)) {
      if (engine.isDirectory()) addScope(sourceFiles(join(engines, engine.name)));
    }
  }

  const tests = [join(root, "app"), engines]
    .filter(existsSync)
    .flatMap((base) => sourceFiles(base, (name) => TEST_FILE.test(name)))
    .sort();
  if (tests.length > 0) scopes.push(tests);

  return scopes;
}

if (configPath) {
  configPath = resolve(configPath);
} else {
  configPath =
    CONFIG_NAMES.map((name) => join(root, name)).find((path) => existsSync(path)) ?? null;
}
if (!configPath) fail(`no ESLint configuration under ${root}; checked 0`);

const scopes = filePath ? [[resolve(filePath)]] : configScopes();
if (scopes.length === 0) fail(`no TypeScript file under ${root}; checked 0`);
const missing = scopes.flat().find((file) => !existsSync(file));
if (missing) fail(`file does not exist: ${missing}; checked 0`);

const eslint = existsSync(join(scriptRoot, "node_modules", ".bin", "eslint"))
  ? join(scriptRoot, "node_modules", ".bin", "eslint")
  : "npx";
const eslintArgs = eslint === "npx" ? ["eslint"] : [];
let checked = 0;

for (const scope of scopes) {
  let resolved = false;
  for (const file of scope.slice(0, SCOPE_ATTEMPTS)) {
    const result = spawnSync(
      eslint,
      [...eslintArgs, "--config", configPath, "--print-config", file],
      { cwd: root, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 },
    );
    if (result.error) fail(`cannot run ESLint: ${result.error.message}; checked 0`);
    if (result.status !== 0) {
      fail(`eslint --print-config failed for ${relative(root, file)}: ${result.stderr.trim()}`);
    }

    const output = result.stdout.trim();
    if (output === "" || output === "undefined") continue;

    let config;
    try {
      config = JSON.parse(output);
    } catch (error) {
      fail(
        `eslint --print-config returned invalid JSON for ${relative(root, file)}: ${error.message}`,
      );
    }

    const parserOptions = config?.languageOptions?.parserOptions ?? {};
    if (parserOptions.project !== undefined) {
      fail(
        `${relative(root, file)} sets parserOptions.project; use projectService so lint stays affected-only (09_enforcement.md)`,
      );
    }

    checked += 1;
    resolved = true;
    break;
  }
  if (!resolved) continue;
}

if (checked === 0) fail(`no lintable TypeScript file under ${root}; checked 0`);

console.log(
  `eslint_config: checked ${checked} config${checked === 1 ? "" : "s"} across ${scopes.length} scope${scopes.length === 1 ? "" : "s"}; parserOptions.project absent`,
);
