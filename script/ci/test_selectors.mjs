#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import ts from "typescript";

let root = process.cwd();
const args = process.argv.slice(2);
for (let index = 0; index < args.length; index += 1) {
  if (args[index] === "--root" && args[index + 1]) {
    root = args[index + 1];
    index += 1;
  }
}
root = path.resolve(root);
if (!fs.existsSync(root) || !fs.statSync(root).isDirectory()) {
  console.error(`test_selectors: root does not exist: ${root}`);
  process.exit(1);
}

const TEST_PATTERNS = [
  /^app\/frontend\/.*\.test\.tsx?$/,
  /^e2e\/.*\.ts$/,
  /^engines\/[^/]+\/app\/frontend\/.*\.test\.tsx?$/,
  /^engines\/[^/]+\/e2e\/.*\.ts$/,
];
const FORBIDDEN =
  /\.(?:get|query|find)(?:All)?By(?:Text|LabelText|PlaceholderText|DisplayValue|Title|AltText)\b|\.(?:getByLabel|getByPlaceholder|getByAltText|getByTitle|locator|querySelector(?:All)?)\b/;
const ROLE = /^(?:get|query|find)(?:All)?ByRole$/;
const MESSAGE = "bad-selector: select by role with an accessible name, or by test id";

const files = [];
function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (entry.name === "node_modules" || entry.name === ".git") continue;
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      walk(full);
      continue;
    }
    const relative = path.relative(root, full).split(path.sep).join("/");
    if (TEST_PATTERNS.some((pattern) => pattern.test(relative))) {
      files.push([full, relative]);
    }
  }
}
walk(root);
files.sort((left, right) => left[1].localeCompare(right[1]));
if (files.length === 0) {
  console.error(`test_selectors: no test files found under ${root}`);
  process.exit(1);
}

function unwrap(expression) {
  let current = expression;
  while (
    ts.isParenthesizedExpression(current) ||
    ts.isAsExpression(current) ||
    ts.isSatisfiesExpression(current)
  ) {
    current = current.expression;
  }
  return current;
}

function hasName(call) {
  if (call.arguments.length < 2) return false;
  const options = unwrap(call.arguments[1]);
  if (!ts.isObjectLiteralExpression(options)) return false;
  return options.properties.some((property) => {
    if (ts.isShorthandPropertyAssignment(property)) {
      return property.name.text === "name";
    }
    if (ts.isPropertyAssignment(property)) {
      return ts.isIdentifier(property.name) && property.name.text === "name";
    }
    return false;
  });
}

let findings = 0;
function report(relative, line) {
  console.log(`${relative}:${line}: ${MESSAGE}`);
  findings += 1;
}

for (const [file, relative] of files) {
  const text = fs.readFileSync(file, "utf8");
  const kind = relative.endsWith(".tsx") ? ts.ScriptKind.TSX : ts.ScriptKind.TS;
  const source = ts.createSourceFile(relative, text, ts.ScriptTarget.Latest, true, kind);
  const lines = new Set();
  text.split(/\r?\n/).forEach((line, index) => {
    if (FORBIDDEN.test(line)) lines.add(index + 1);
  });
  function visit(node) {
    if (ts.isCallExpression(node)) {
      const expression = node.expression;
      const role = ts.isPropertyAccessExpression(expression)
        ? expression.name.text
        : ts.isIdentifier(expression)
          ? expression.text
          : null;
      if (role && ROLE.test(role) && !hasName(node)) {
        lines.add(source.getLineAndCharacterOfPosition(node.getStart(source)).line + 1);
      }
    }
    ts.forEachChild(node, visit);
  }
  visit(source);
  for (const line of [...lines].sort((a, b) => a - b)) {
    report(relative, line);
  }
}

console.error(`test_selectors: checked ${files.length} test files; findings=${findings}`);
process.exit(findings === 0 ? 0 : 1);
