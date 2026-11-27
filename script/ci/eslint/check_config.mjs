// Fails when the resolved ESLint config sets parserOptions.project: type-aware
// rules may run only through projectService, so lint stays affected-only
// (09_enforcement.md, TS-07). `npm run lint` runs this before ESLint.
//
// Every TypeScript file in every scope (root, app, each engine, script, e2e)
// is resolved through ESLint's own configuration loader, in byte order, so a
// path-scoped override or an ignored prefix cannot hide one. A file or scope
// the check cannot resolve fails closed; it is never left out silently.
import { existsSync, readdirSync, statSync } from "node:fs";
import { join, relative, resolve } from "node:path";

import { ESLint } from "eslint";

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
// ESLint's flat-config file names. The check only proves one exists; ESLint's
// own loader decides which one wins, so the check cannot disagree with it.
const CONFIG_NAMES = [
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
];

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
if (!configPath && !CONFIG_NAMES.some((name) => existsSync(join(root, name)))) {
  fail(`no ESLint configuration under ${root}; checked 0`);
}

function sortedEntries(directory) {
  return readdirSync(directory, { withFileTypes: true }).sort((left, right) =>
    left.name < right.name ? -1 : left.name > right.name ? 1 : 0,
  );
}

function sourceFiles(directory) {
  const files = [];
  if (!existsSync(directory)) return files;
  for (const entry of sortedEntries(directory)) {
    if (entry.isDirectory()) {
      if (SKIP_DIRECTORIES.has(entry.name)) continue;
      files.push(...sourceFiles(join(directory, entry.name)));
    } else if (SOURCE_FILE.test(entry.name)) {
      files.push(join(directory, entry.name));
    }
  }
  return files;
}

function configScopes() {
  const scopes = [];
  const addScope = (name, files) => {
    if (files.length > 0) scopes.push({ name, files });
  };

  addScope(
    "root",
    sortedEntries(root)
      .filter((entry) => entry.isFile() && SOURCE_FILE.test(entry.name))
      .map((entry) => join(root, entry.name)),
  );
  for (const directory of ["app", "e2e", "script"]) {
    addScope(directory, sourceFiles(join(root, directory)));
  }

  const engines = join(root, "engines");
  if (existsSync(engines)) {
    for (const engine of sortedEntries(engines)) {
      if (engine.isDirectory())
        addScope(`engines/${engine.name}`, sourceFiles(join(engines, engine.name)));
    }
  }

  return scopes;
}

const eslintOptions = { cwd: root };
if (configPath) {
  configPath = resolve(configPath);
  if (!existsSync(configPath)) fail(`config does not exist: ${configPath}; checked 0`);
  eslintOptions.overrideConfigFile = configPath;
}

let scopes;
if (filePath) {
  const file = resolve(root, filePath);
  if (!existsSync(file) || !statSync(file).isFile()) {
    fail(`file does not exist: ${file}; checked 0`);
  }
  scopes = [{ name: relative(root, file), files: [file] }];
} else {
  scopes = configScopes();
}
if (scopes.length === 0) fail(`no TypeScript file under ${root}; checked 0`);

const eslint = new ESLint(eslintOptions);
let checkedFiles = 0;
let checkedScopes = 0;

for (const scope of scopes) {
  let resolved = 0;
  for (const file of scope.files) {
    let ignored;
    try {
      ignored = await eslint.isPathIgnored(file);
    } catch (error) {
      if (/could not find config file/i.test(error.message)) {
        fail(`no ESLint configuration under ${root}; checked 0`);
      }
      fail(`${relative(root, file)}: ${error.message}; checked 0`);
    }
    if (ignored) continue;

    let config;
    try {
      config = await eslint.calculateConfigForFile(file);
    } catch (error) {
      if (/could not find config file/i.test(error.message)) {
        fail(`no ESLint configuration under ${root}; checked 0`);
      }
      fail(`${relative(root, file)}: ${error.message}; checked 0`);
    }

    const parserOptions = config?.languageOptions?.parserOptions ?? {};
    if (parserOptions.project !== undefined) {
      fail(
        `${relative(root, file)} sets parserOptions.project; use projectService so lint stays affected-only (09_enforcement.md, TS-07)`,
      );
    }

    resolved += 1;
    checkedFiles += 1;
  }
  if (resolved > 0) checkedScopes += 1;
}

if (checkedFiles === 0) {
  fail(`no lintable TypeScript file under ${root}; checked 0`);
}

console.log(
  `eslint_config: checked ${checkedFiles} file${checkedFiles === 1 ? "" : "s"} across ${checkedScopes} scope${checkedScopes === 1 ? "" : "s"}; parserOptions.project absent`,
);
