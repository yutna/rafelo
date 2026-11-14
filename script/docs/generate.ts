import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

import {
  aiFiles,
  checkCitations,
  checkGenerated,
  checkMatrix,
  checkPaths,
  collectDefinitions,
  loadConfig,
  readTextFiles,
  rewriteGenerated,
  topicFiles,
  type Finding,
  type PathSource
} from "./lib";

const rootArg = process.argv.indexOf("--root");
const root = rootArg >= 0 ? resolve(process.argv[rootArg + 1]) : process.cwd();
const check = process.argv.includes("--check");
const contractsPath = resolve(root, "docs/contracts.md");

function fail(message: string): never {
  console.error(`docs: ${message}`);
  process.exit(1);
}

if (!existsSync(root)) fail(`root does not exist: ${root}`);

const { config, findings: configFindings } = loadConfig(root);
if (!config) {
  configFindings.forEach((finding) => console.error(`docs: ${finding.file}: ${finding.message}`));
  fail(`configuration has ${configFindings.length} finding(s)`);
}

if (!check) {
  const text = readFileSync(contractsPath, "utf8");
  writeFileSync(contractsPath, rewriteGenerated(text));
  console.log("docs: generated the envelope table");
  process.exit(0);
}

const topics = topicFiles(root);
if (topics.length === 0) fail("no topic file was found");
const instructions = aiFiles(root, config);
const topicText = readTextFiles(root, topics);
const instructionText = readTextFiles(root, instructions);
const generated = readFileSync(contractsPath, "utf8");

const definitions = collectDefinitions(topicText);
const matrix = checkMatrix(readTextFiles(root, ["docs/architecture/09_enforcement.md"])[0].text, definitions.definitions);
const citations = checkCitations([ ...topicText, ...instructionText ], definitions.definitions);

const sources: PathSource[] = [
  ...topicText.map(({ file, text }) => ({ file, text, kind: "topic" as const })),
  ...instructionText.map(({ file, text }) => ({ file, text, kind: "instruction" as const }))
];
const paths = checkPaths(root, sources, config.deferred_paths);
if (paths.paths === 0) {
  fail("no repository path was found to check");
}

const findings: Finding[] = [
  ...configFindings,
  ...definitions.findings,
  ...matrix.findings,
  ...citations.findings,
  ...paths.findings,
  ...checkGenerated(generated)
];

if (findings.length > 0) {
  findings.forEach((finding) => console.error(`docs: ${finding.file}${finding.line ? `:${finding.line}` : ""}: ${finding.message}`));
  fail(`check found ${findings.length} finding(s)`);
}

console.log(
  `docs: checked ${topics.length} topic file(s), ${instructions.length} AI file(s), ` +
  `${definitions.definitions.size} definition(s), ${matrix.rows} matrix row(s), ` +
  `${citations.citations} citation(s), ${paths.paths} path(s); findings=0`
);
