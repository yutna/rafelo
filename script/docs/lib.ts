import { spawnSync } from "node:child_process";
import { existsSync, globSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { parse as parseYaml } from "yaml";
import { z } from "zod";

import { sharedPropsSchema } from "@core/contracts/page_props.schema";

export const RULE_PREFIXES = ["ARCH", "BE", "CT", "FE", "GEN", "OPS", "SEC", "TS", "WF", "OOP"] as const;
export const STATUSES = ["enforced", "tested in kernel", "verify when adopting", "review"] as const;
export const GENERATED_START = "<!-- generated:envelope:start -->";
export const GENERATED_END = "<!-- generated:envelope:end -->";

const ALL_PATH_PREFIXES = ["script/", "bin/", "spec/", "engines/", "config/", "app/", ".github/"] as const;
const TOPIC_PATH_PREFIXES = ["script/", "bin/", ".github/", "engines/core/", "engines/design_system/"] as const;
const ID_PATTERN = /\b(ARCH|BE|CT|FE|GEN|OPS|SEC|TS|WF|OOP|ADR)-(\d{2})\b/g;

export type Finding = { file: string; line?: number; message: string };
export type TextFile = { file: string; text: string };
export type Definition = {
  id: string;
  kind: "rule" | "adr";
  file: string;
  line: number;
  strength?: string;
  decisions?: string[];
  status?: "accepted" | "superseded";
  supersededBy?: string;
};
export type DocsConfig = {
  ai_instruction_files: string[];
  deferred_paths: Record<string, string>;
};

export function isRuleId(id: string): boolean {
  return RULE_PREFIXES.some((prefix) => id.startsWith(`${prefix}-`));
}

export function loadConfig(root: string): { config?: DocsConfig; findings: Finding[] } {
  const path = "config/docs.yml";
  if (!existsSync(resolve(root, path))) {
    return { findings: [{ file: path, message: "the docs configuration is missing" }] };
  }

  let parsed: unknown;
  try {
    parsed = parseYaml(readFileSync(resolve(root, path), "utf8"));
  } catch (error) {
    return { findings: [{ file: path, message: `cannot parse YAML: ${(error as Error).message}` }] };
  }

  const raw = (parsed ?? {}) as Record<string, unknown>;
  const files = raw.ai_instruction_files;
  const deferred = raw.deferred_paths;
  const findings: Finding[] = [];

  if (!Array.isArray(files) || files.length === 0 || files.some((entry) => typeof entry !== "string")) {
    findings.push({ file: path, message: "ai_instruction_files must be a non-empty list of paths and globs" });
  }
  if (deferred !== undefined && (deferred === null || typeof deferred !== "object" || Array.isArray(deferred))) {
    findings.push({ file: path, message: "deferred_paths must be a mapping of path to reason" });
  }

  return {
    config: findings.length === 0
      ? { ai_instruction_files: files as string[], deferred_paths: (deferred ?? {}) as Record<string, string> }
      : undefined,
    findings
  };
}

export function topicFiles(root: string): string[] {
  return globSync("docs/architecture/[0-9][0-9]_*.md", { cwd: root })
    .map((path) => path.split("\\").join("/"))
    .sort();
}

export function aiFiles(root: string, config: DocsConfig): string[] {
  const files = new Set<string>();
  for (const path of globSync("**/AGENTS.md", { cwd: root })) files.add(path.split("\\").join("/"));
  for (const path of globSync("**/CLAUDE.md", { cwd: root })) files.add(path.split("\\").join("/"));
  for (const pattern of config.ai_instruction_files) {
    for (const path of globSync(pattern, { cwd: root })) files.add(path.split("\\").join("/"));
  }
  return [...files]
    .filter((path) => !path.startsWith("node_modules/") && !path.startsWith("tmp/") && !path.startsWith("vendor/") && !path.startsWith(".git/"))
    .sort();
}

export function readTextFiles(root: string, paths: string[]): TextFile[] {
  return paths.map((file) => ({ file, text: readFileSync(resolve(root, file), "utf8") }));
}

function isFence(line: string): boolean {
  return /^\s*```/.test(line);
}

export function collectDefinitions(files: TextFile[]): { definitions: Map<string, Definition>; findings: Finding[] } {
  const definitions = new Map<string, Definition>();
  const findings: Finding[] = [];

  for (const { file, text } of files) {
    const lines = text.split("\n");
    let inFence = false;

    lines.forEach((line, index) => {
      if (isFence(line)) {
        inFence = !inFence;
        return;
      }
      if (inFence) return;

      const heading = line.match(/^#{2,6}\s+([A-Z]{2,5}-\d{2})\s+—\s+(.+?)\s*$/);
      if (!heading) return;

      const id = heading[1];
      const title = heading[2];
      const lineNumber = index + 1;
      if (definitions.has(id)) {
        findings.push({ file, line: lineNumber, message: `${id} is defined more than once (first at ${definitions.get(id)!.file}:${definitions.get(id)!.line})` });
        return;
      }

      if (id.startsWith("ADR-")) {
        let statusLine: string | undefined;
        for (let cursor = index + 1; cursor < lines.length; cursor += 1) {
          if (/^#{2,6}\s+/.test(lines[cursor])) break;
          const status = lines[cursor].match(/^Status:\s*(.+?)\s*$/);
          if (status) {
            statusLine = status[1];
            break;
          }
        }
        if (!statusLine) {
          findings.push({ file, line: lineNumber, message: `${id} has no Status: line` });
          return;
        }
        if (statusLine === "Accepted") {
          definitions.set(id, { id, kind: "adr", file, line: lineNumber, status: "accepted" });
        } else {
          const superseded = statusLine.match(/^Superseded by (ADR-\d{2})$/);
          if (!superseded) {
            findings.push({ file, line: lineNumber, message: `${id} has an unknown status "${statusLine}"` });
            return;
          }
          definitions.set(id, { id, kind: "adr", file, line: lineNumber, status: "superseded", supersededBy: superseded[1] });
        }
        return;
      }

      if (!isRuleId(id)) {
        findings.push({ file, line: lineNumber, message: `${id} is not a known rule prefix` });
        return;
      }

      const decision = title.match(/^(.*?)\s*\(([^()]*)\)\s*$/);
      if (!decision) {
        findings.push({ file, line: lineNumber, message: `${id} does not end with its strength and decisions` });
        return;
      }
      const parts = decision[2].split("·").map((part) => part.trim());
      const strength = parts[0];
      if (!["MUST", "SHOULD", "MAY"].includes(strength) || parts.length < 2) {
        findings.push({ file, line: lineNumber, message: `${id} does not state (MUST|SHOULD|MAY · ADR-NN)` });
        return;
      }
      const decisions = parts.slice(1).join("·").split(",").map((part) => part.trim()).filter(Boolean);
      if (decisions.length === 0 || decisions.some((entry) => !/^ADR-\d{2}$/.test(entry))) {
        findings.push({ file, line: lineNumber, message: `${id} does not name an ADR decision` });
        return;
      }
      definitions.set(id, { id, kind: "rule", file, line: lineNumber, strength, decisions });
    });
  }

  if (definitions.size === 0) {
    findings.push({ file: "docs/architecture", message: "no rule or ADR definition was found" });
  }

  for (const definition of definitions.values()) {
    const references = definition.kind === "rule" ? definition.decisions ?? [] : definition.supersededBy ? [definition.supersededBy] : [];
    for (const reference of references) {
      if (!definitions.has(reference)) {
        findings.push({ file: definition.file, line: definition.line, message: `${definition.id} cites undefined ${reference}` });
      }
    }
  }

  return { definitions, findings };
}

export function checkMatrix(text: string, definitions: Map<string, Definition>): { rows: number; findings: Finding[] } {
  const findings: Finding[] = [];
  const counts = new Map<string, number>();
  let rows = 0;

  for (const [index, line] of text.split("\n").entries()) {
    const match = line.match(/^\|\s*([A-Z]{2,5}-\d{2})\s*\|/);
    if (!match) continue;

    const id = match[1];
    rows += 1;
    counts.set(id, (counts.get(id) ?? 0) + 1);
    const cells = line.split("|").map((cell) => cell.trim());
    const rawStatus = cells[3] ?? "";
    let status = rawStatus;
    while (/\([^()]*\)/.test(status)) status = status.replace(/\([^()]*\)/g, " ");
    const values = status.split(/·|\+/).map((value) => value.trim()).filter(Boolean);
    if (values.length === 0 || values.some((value) => !STATUSES.includes(value as (typeof STATUSES)[number]))) {
      findings.push({ file: "docs/architecture/09_enforcement.md", line: index + 1, message: `${id} has an unknown enforcement status "${rawStatus}"` });
    }
    if (!definitions.has(id)) {
      findings.push({ file: "docs/architecture/09_enforcement.md", line: index + 1, message: `${id} has a row but no definition` });
    }
  }

  for (const definition of definitions.values()) {
    if (definition.kind !== "rule") continue;
    const count = counts.get(definition.id) ?? 0;
    if (count !== 1) {
      findings.push({ file: definition.file, line: definition.line, message: `${definition.id} has ${count} enforcement rows, expected exactly 1` });
    }
  }

  if (rows === 0) {
    findings.push({ file: "docs/architecture/09_enforcement.md", message: "the enforcement matrix has no rows" });
  }

  return { rows, findings };
}

export function checkCitations(files: TextFile[], definitions: Map<string, Definition>): { citations: number; findings: Finding[] } {
  const findings: Finding[] = [];
  let citations = 0;

  for (const { file, text } of files) {
    text.split("\n").forEach((line, index) => {
      for (const match of line.matchAll(ID_PATTERN)) {
        citations += 1;
        const id = `${match[1]}-${match[2]}`;
        const definition = definitions.get(id);
        if (!definition) {
          findings.push({ file, line: index + 1, message: `${id} is cited but not defined` });
        } else if (definition.kind === "adr" && definition.status === "superseded") {
          findings.push({ file, line: index + 1, message: `${id} is superseded by ${definition.supersededBy}` });
        }
      }
    });
  }

  return { citations, findings };
}

function pathTokens(span: string): string[] {
  const tokens = span.match(/(?:script|bin|spec|engines|config|app|\.github)\/[^\s`]+/g) ?? [];
  return tokens
    .map((token) => token.replace(/^[("'[]+/, "").replace(/[)"'\].,;:]+$/, "").replace(/:\d+$/, "").replace(/#.*$/, "").replace(/\/+$/, ""))
    .filter(Boolean);
}

function hasPlaceholder(token: string): boolean {
  return /[<>*{}$%?[\]|]|\.\.\./.test(token);
}

export type PathSource = { file: string; text: string; kind: "topic" | "instruction" };

export function checkPaths(
  root: string,
  sources: PathSource[],
  deferred: Record<string, string>,
  options: { ignored?: (path: string) => boolean } = {}
): { paths: number; findings: Finding[] } {
  const findings: Finding[] = [];
  const candidates = new Map<string, { file: string; line: number }>();
  let checked = 0;

  for (const source of sources) {
    const prefixes = source.kind === "instruction" ? ALL_PATH_PREFIXES : TOPIC_PATH_PREFIXES;
    source.text.split("\n").forEach((line, index) => {
      for (const span of line.matchAll(/`([^`\n]+)`/g)) {
        for (const token of pathTokens(span[1])) {
          if (hasPlaceholder(token)) continue;
          if (!prefixes.some((prefix) => token === prefix.replace(/\/$/, "") || token.startsWith(prefix))) continue;
          if (!candidates.has(token)) candidates.set(token, { file: source.file, line: index + 1 });
        }
      }
    });
  }

  const ignored = options.ignored ?? ((path: string) => ignoredByGit(root, path));
  for (const [token, place] of candidates) {
    if (deferred[token]) {
      if (existsSync(resolve(root, token))) {
        findings.push({ file: place.file, line: place.line, message: `${token} now exists; remove it from deferred_paths in config/docs.yml` });
      }
      continue;
    }
    if (ignored(token)) continue;
    checked += 1;
    if (!existsSync(resolve(root, token))) {
      findings.push({ file: place.file, line: place.line, message: `names missing path ${token}` });
    }
  }

  return { paths: checked, findings };
}

export function ignoredByGit(root: string, path: string): boolean {
  if (!existsSync(resolve(root, ".git"))) return false;
  const result = spawnSync("git", ["-C", root, "check-ignore", "--quiet", "--", path], { encoding: "utf8" });
  return result.status === 0;
}

function shape(node: Record<string, unknown>): string {
  if (!node || typeof node !== "object") return "unknown";
  if (Array.isArray(node.anyOf)) return node.anyOf.map((entry) => shape(entry as Record<string, unknown>)).join(" or ");
  if (Array.isArray(node.type)) return node.type.map((type) => (type === "null" ? "null" : String(type))).join(" or ");
  if (node.type === "object" && node.properties) {
    const properties = Object.entries(node.properties as Record<string, Record<string, unknown>>)
      .map(([key, value]) => `${key}: ${shape(value)}`)
      .join(", ");
    return `object (${properties})`;
  }
  if (node.type === "object" && node.additionalProperties) {
    return `object of ${shape(node.additionalProperties as Record<string, unknown>)}`;
  }
  if (node.type === "array") return `array of ${shape(node.items as Record<string, unknown>)}`;
  if (Array.isArray(node.enum)) return node.enum.map((value) => `\`${String(value)}\``).join(" or ");
  if (node.const !== undefined) return `\`${String(node.const)}\``;
  return String(node.type ?? "unknown");
}

export function envelopeTable(): string {
  const schema = z.toJSONSchema(sharedPropsSchema, { io: "output", target: "draft-2020-12" }) as Record<string, unknown>;
  const required = new Set(schema.required as string[] | undefined);
  const properties = (schema.properties ?? {}) as Record<string, Record<string, unknown>>;
  const rows = Object.entries(properties).map(([name, value]) => `| \`${name}\` | ${shape(value)} | ${required.has(name) ? "yes" : "no"} |`);
  return [ "| Field | Shape | Required |", "| --- | --- | --- |", ...rows ].join("\n");
}

export function rewriteGenerated(text: string): string {
  const start = text.indexOf(GENERATED_START);
  const end = text.indexOf(GENERATED_END);
  if (start < 0 || end < 0 || end < start) {
    throw new Error(`the generated envelope markers are missing or out of order (${GENERATED_START} / ${GENERATED_END})`);
  }
  return text.slice(0, start + GENERATED_START.length) + "\n" + envelopeTable() + "\n" + text.slice(end);
}

export function checkGenerated(text: string): Finding[] {
  let expected: string;
  try {
    expected = rewriteGenerated(text);
  } catch (error) {
    return [{ file: "docs/contracts.md", message: (error as Error).message }];
  }
  return expected === text
    ? []
    : [{ file: "docs/contracts.md", message: "the generated envelope table is stale; run npm run docs:generate" }];
}
