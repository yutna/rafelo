import { globSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, relative, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { z } from "zod";

import { sharedPropsSchema } from "@core/contracts/page_props.schema";

const root = process.cwd();
const check = process.argv.includes("--check");
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

console.log(`contracts: ${check ? "checked" : "generated"} ${sources.length} page schema(s)`);
