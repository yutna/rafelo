import { existsSync, globSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, relative, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { z } from "zod";

import { sharedPropsSchema } from "@core/contracts/page_props.schema";

const rootArg = process.argv.indexOf("--root");
const root = rootArg >= 0 ? resolve(process.argv[rootArg + 1]) : process.cwd();
const check = process.argv.includes("--check");
if (!existsSync(root)) {
  console.error(`contracts: root does not exist: ${root}`);
  process.exit(1);
}
const sharedUri = "https://rafelo.local/contracts/_shared.json";
const pageKeys = ["data", "meta", "query", "pagination", "can"];
const sharedKeys = Object.keys(sharedPropsSchema.shape);
const expectedKeys = [...sharedKeys, ...pageKeys].sort();

function fail(message: string): never {
  console.error(`contracts: ${message}`);
  process.exit(1);
}

function outputPath(source: string): string {
  if (source.startsWith("app/frontend/pages/")) {
    return resolve(root, "config/contracts/pages", relative("app/frontend/pages", source).replace(/\.schema\.ts$/, ".json"));
  }
  const match = source.match(/^engines\/([^/]+)\/app\/frontend\/pages\//);
  if (!match) {
    fail(`unexpected page schema path ${source}`);
  }
  return resolve(root, "engines", match[1], "config/contracts/pages", relative(`engines/${match[1]}/app/frontend/pages`, source).replace(/\.schema\.ts$/, ".json"));
}

function checkStringIds(value: unknown, path: string) {
  if (!value || typeof value !== "object") return;
  const node = value as Record<string, unknown>;
  const properties = node.properties as Record<string, Record<string, unknown>> | undefined;
  if (properties) {
    for (const [key, property] of Object.entries(properties)) {
      if ((key === "id" || key.endsWith("Id")) && property.type !== "string") {
        fail(`${path}.${key} must be a string`);
      }
      checkStringIds(property, `${path}.${key}`);
    }
  }
  for (const key of ["items", "anyOf", "oneOf", "allOf", "additionalProperties"]) {
    const child = node[key];
    if (Array.isArray(child)) child.forEach((entry, index) => checkStringIds(entry, `${path}.${key}[${index}]`));
    else checkStringIds(child, `${path}.${key}`);
  }
}

function writeGenerated(path: string, value: unknown) {
  const content = `${JSON.stringify(value, null, 2)}\n`;
  if (check) {
    let current = "";
    try {
      current = readFileSync(path, "utf8");
    } catch {
      fail(`${relative(root, path)} is missing`);
    }
    if (current !== content) {
      fail(`${relative(root, path)} is stale`);
    }
    return;
  }
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}

const shared = z.toJSONSchema(sharedPropsSchema, { io: "output", target: "draft-2020-12" });
shared.$id = sharedUri;
checkStringIds(shared, "_shared");
writeGenerated(resolve(root, "config/contracts/_shared.json"), shared);

const sources = [
  ...globSync("app/frontend/pages/**/*.schema.ts", { cwd: root }),
  ...globSync("engines/*/app/frontend/pages/**/*.schema.ts", { cwd: root }),
].sort();

if (sources.length === 0) {
  fail("no page schemas found");
}

for (const source of sources) {
  const module = await import(pathToFileURL(resolve(root, source)).href);
  const pageSchema = module.pageSchema;
  if (!pageSchema) {
    fail(`${source} does not export pageSchema`);
  }
  const schema = z.toJSONSchema(pageSchema, { io: "output", target: "draft-2020-12" }) as Record<string, any>;
  checkStringIds(schema, source);
  const properties = (schema.properties ?? {}) as Record<string, unknown>;
  schema.properties = properties;
  const keys = Object.keys(properties).sort();
  if (JSON.stringify(keys) !== JSON.stringify(expectedKeys)) {
    fail(`${source} does not use definePage (keys ${keys.join(", ")})`);
  }
  for (const key of sharedKeys) {
    properties[key] = { $ref: `${sharedUri}#/properties/${key}` };
  }
  writeGenerated(outputPath(source), schema);
}

const expectedOutputs = new Set(
  sources.map((source) => outputPath(source)),
);
for (const pattern of ["config/contracts/pages/**/*.json", "engines/*/config/contracts/pages/**/*.json"]) {
  for (const path of globSync(pattern, { cwd: root })) {
    const full = resolve(root, path);
    if (!expectedOutputs.has(full)) fail(`${path} has no page schema`);
  }
}

console.log(`contracts: ${check ? "checked" : "generated"} ${sources.length} page schema(s)`);
