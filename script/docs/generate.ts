import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

import {
  aiFiles,
  checkCitations,
  checkGenerated,
  checkHeldBack,
  checkMatrix,
  checkPackConflicts,
  checkPaths,
  collectDefinitions,
  heldBackTable,
  loadConfig,
  loadHeldBack,
  readTextFiles,
  rewriteGenerated,
  rewriteHeldBack,
  topicFiles,
  type Finding,
  type PathSource,
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

const readmePath = resolve(root, "docs/architecture/00_README.md");

if (!check) {
  const text = readFileSync(contractsPath, "utf8");
  writeFileSync(contractsPath, rewriteGenerated(text));
  const heldBack = loadHeldBack(root);
  if (heldBack.findings.length > 0) {
    heldBack.findings.forEach((finding) =>
      console.error(`docs: ${finding.file}: ${finding.message}`),
    );
    fail(`the held-back rules have ${heldBack.findings.length} finding(s)`);
  }
  const readme = readFileSync(readmePath, "utf8");
  writeFileSync(readmePath, rewriteHeldBack(readme, heldBackTable(heldBack.rows ?? [])));
  console.log("docs: generated the envelope and held-back tables");
  process.exit(0);
}

const topics = topicFiles(root);
if (topics.length === 0) fail("no topic file was found");
const { files: instructions, findings: instructionFindings } = aiFiles(root, config);
const topicText = readTextFiles(root, topics);
const instructionText = readTextFiles(root, instructions);
const generated = readFileSync(contractsPath, "utf8");
const readme = readFileSync(readmePath, "utf8");
const heldBack = loadHeldBack(root);
const heldBackFindings =
  heldBack.rows === undefined
    ? heldBack.findings
    : [...heldBack.findings, ...checkHeldBack(readme, heldBackTable(heldBack.rows))];

const definitions = collectDefinitions(topicText);
const matrix = checkMatrix(
  readTextFiles(root, ["docs/architecture/09_enforcement.md"])[0].text,
  definitions.definitions,
);
const citations = checkCitations([...topicText, ...instructionText], definitions.definitions);
const rootGuide = instructionText.find(({ file }) => file === "AGENTS.md");
const packConflicts = checkPackConflicts(rootGuide?.text ?? "");

const sources: PathSource[] = [
  ...topicText.map(({ file, text }) => ({ file, text, kind: "topic" as const })),
  ...instructionText.map(({ file, text }) => ({ file, text, kind: "instruction" as const })),
];
const paths = checkPaths(root, sources);
if (paths.paths === 0) {
  fail("no repository path was found to check");
}

const findings: Finding[] = [
  ...configFindings,
  ...instructionFindings,
  ...definitions.findings,
  ...matrix.findings,
  ...citations.findings,
  ...packConflicts,
  ...paths.findings,
  ...checkGenerated(generated),
  ...heldBackFindings,
];

if (findings.length > 0) {
  findings.forEach((finding) =>
    console.error(
      `docs: ${finding.file}${finding.line ? `:${finding.line}` : ""}: ${finding.message}`,
    ),
  );
  fail(`check found ${findings.length} finding(s)`);
}

console.log(
  `docs: checked ${topics.length} topic file(s), ${instructions.length} AI file(s), ` +
    `${definitions.definitions.size} definition(s), ${matrix.rows} matrix row(s), ` +
    `${citations.citations} citation(s), ${paths.paths} path(s); findings=0`,
);
