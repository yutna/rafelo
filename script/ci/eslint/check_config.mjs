// Fails when the resolved ESLint config sets parserOptions.project: type-aware
// rules may run only through projectService, so lint stays affected-only
// (09_enforcement.md, TS-07). `npm run lint` runs this before ESLint.
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

function findFirstFile(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (SKIP_DIRECTORIES.has(entry.name)) continue;
      const found = findFirstFile(join(directory, entry.name));
      if (found) return found;
    } else if (/\.(?:ts|tsx|mts|cts)$/.test(entry.name)) {
      return join(directory, entry.name);
    }
  }
  return null;
}

if (configPath) {
  configPath = resolve(configPath);
} else {
  configPath =
    CONFIG_NAMES.map((name) => join(root, name)).find((path) => existsSync(path)) ?? null;
}
if (!configPath) fail(`no ESLint configuration under ${root}; checked 0`);

filePath = filePath ? resolve(filePath) : findFirstFile(root);
if (!filePath) fail(`no TypeScript file under ${root}; checked 0`);

const eslint = existsSync(join(scriptRoot, "node_modules", ".bin", "eslint"))
  ? join(scriptRoot, "node_modules", ".bin", "eslint")
  : "npx";
const eslintArgs = eslint === "npx" ? ["eslint"] : [];
const result = spawnSync(
  eslint,
  [...eslintArgs, "--config", configPath, "--print-config", filePath],
  { cwd: root, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 },
);
if (result.error) fail(`cannot run ESLint: ${result.error.message}; checked 0`);
if (result.status !== 0) {
  fail(`eslint --print-config failed for ${relative(root, filePath)}: ${result.stderr.trim()}`);
}

let config;
try {
  config = JSON.parse(result.stdout);
} catch (error) {
  fail(`eslint --print-config returned invalid JSON: ${error.message}`);
}

const parserOptions = config?.languageOptions?.parserOptions ?? {};
if (parserOptions.project !== undefined) {
  fail(
    `${relative(root, filePath)} sets parserOptions.project; use projectService so lint stays affected-only (09_enforcement.md)`,
  );
}

console.log(
  `eslint_config: checked 1 config for ${relative(root, filePath)}; parserOptions.project absent`,
);
