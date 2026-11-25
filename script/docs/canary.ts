import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";

import {
  aiFiles,
  checkCitations,
  checkEnvelopeTable,
  checkGenerated,
  checkHeldBack,
  checkMatrix,
  checkPackConflicts,
  checkPaths,
  collectDefinitions,
  heldBackRows,
  heldBackTable,
  PACK_CONFLICTS,
  rewriteGenerated,
  rewriteHeldBack,
  type Definition,
  type Finding,
} from "./lib";

let cases = 0;
let failures = 0;

function expectFinding(name: string, findings: Finding[], pattern: RegExp): void {
  cases += 1;
  if (!findings.some((finding) => pattern.test(finding.message))) {
    failures += 1;
    console.error(
      `docs:canary: ${name}: expected ${pattern}, got ${JSON.stringify(findings.map((finding) => finding.message))}`,
    );
  }
}

function expectNone(name: string, findings: Finding[]): void {
  cases += 1;
  if (findings.length > 0) {
    failures += 1;
    console.error(
      `docs:canary: ${name}: expected no findings, got ${JSON.stringify(findings.map((finding) => finding.message))}`,
    );
  }
}

function expect(name: string, condition: boolean): void {
  cases += 1;
  if (!condition) {
    failures += 1;
    console.error(`docs:canary: ${name}: expected true`);
  }
}

function rule(id: string, strength = "MUST", decision = "ADR-01"): string {
  return `### ${id} — Title (${strength} · ${decision})\n`;
}

function adr(id: string, status = "Accepted"): string {
  return `### ${id} — Title\n\nStatus: ${status}\n`;
}

function matrix(id: string, status = "enforced"): string {
  return `| ${id} | tool | ${status} |\n`;
}

function definitions(files: { file: string; text: string }[]): Map<string, Definition> {
  return collectDefinitions(files).definitions;
}

// Definitions and citations.
const baseDefinitions = collectDefinitions([
  { file: "docs/architecture/01_test.md", text: rule("ARCH-01") + "\n" + adr("ADR-01") },
]);
expectNone("valid definitions and matrix", [
  ...baseDefinitions.findings,
  ...checkMatrix(matrix("ARCH-01"), baseDefinitions.definitions).findings,
]);

const duplicate = collectDefinitions([
  { file: "docs/architecture/01_test.md", text: rule("ARCH-01") + rule("ARCH-01") },
]);
expectFinding("duplicate id", duplicate.findings, /defined more than once/);

const fenced = collectDefinitions([
  {
    file: "docs/architecture/01_test.md",
    text: "```text\n" + rule("ARCH-01") + "```\n" + rule("ARCH-02"),
  },
]);
expect(
  "heading inside a fence is not a definition",
  !fenced.definitions.has("ARCH-01") && fenced.definitions.has("ARCH-02"),
);

const badHeading = collectDefinitions([
  { file: "docs/architecture/01_test.md", text: "### ARCH-01 — Title without a decision\n" },
]);
expectFinding("bad rule heading", badHeading.findings, /does not end with its strength/);

const unknownStrength = collectDefinitions([
  { file: "docs/architecture/01_test.md", text: rule("ARCH-01", "ALWAYS") },
]);
expectFinding("unknown strength", unknownStrength.findings, /does not state/);

const missingAdr = collectDefinitions([
  { file: "docs/architecture/01_test.md", text: rule("ARCH-01", "MUST", "ADR-99") },
]);
expectFinding("undefined decision", missingAdr.findings, /cites undefined ADR-99/);

const noDefinitions = collectDefinitions([
  { file: "docs/architecture/01_test.md", text: "Nothing here\n" },
]);
expectFinding("no definitions", noDefinitions.findings, /no rule or ADR definition was found/);

const ruleDefinitions = definitions([
  { file: "docs/architecture/01_test.md", text: rule("ARCH-01") + adr("ADR-01") },
]);
expectFinding(
  "rule without a row",
  checkMatrix("", ruleDefinitions).findings,
  /0 enforcement rows/,
);
expectFinding(
  "rule with two rows",
  checkMatrix(matrix("ARCH-01") + matrix("ARCH-01"), ruleDefinitions).findings,
  /2 enforcement rows/,
);
expectFinding(
  "row without a definition",
  checkMatrix(matrix("ARCH-09"), ruleDefinitions).findings,
  /has a row but no definition/,
);
expectFinding(
  "unknown status",
  checkMatrix(matrix("ARCH-01", "sometimes"), ruleDefinitions).findings,
  /unknown enforcement status/,
);
expectNone(
  "status with a scope",
  checkMatrix(matrix("ARCH-01", "enforced (plan features: verify when adopting)"), ruleDefinitions)
    .findings,
);

const superseded = collectDefinitions([
  {
    file: "docs/architecture/01_test.md",
    text: rule("ARCH-01") + adr("ADR-01") + adr("ADR-02", "Superseded by ADR-01"),
  },
]);
expectNone("superseded definition", superseded.findings);
expectFinding(
  "superseded citation",
  checkCitations(
    [{ file: "docs/architecture/02_test.md", text: "See ADR-02." }],
    superseded.definitions,
  ).findings,
  /ADR-02 is superseded by ADR-01/,
);
expectFinding(
  "unknown citation",
  checkCitations(
    [{ file: "docs/architecture/02_test.md", text: "See ARCH-99." }],
    superseded.definitions,
  ).findings,
  /ARCH-99 is cited but not defined/,
);

// Paths.
const root = mkdtempSync(join(tmpdir(), "rafelo-docs-canary-"));
try {
  for (const path of [
    "script/ci/exists",
    "engines/core/lib/present.rb",
    "config/locales/en.yml",
    ".github/workflows/ci.yml",
  ]) {
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), "canary\n");
  }
  mkdirSync(join(root, "template", ".github", "workflows"), { recursive: true });
  writeFileSync(join(root, "template", ".github", "workflows", "pull_request.yml"), "canary\n");

  const topic = (text: string) => [
    { file: "docs/architecture/01_test.md", text, kind: "topic" as const },
  ];
  const instruction = (text: string) => [{ file: "AGENTS.md", text, kind: "instruction" as const }];
  const noIgnore = { ignored: () => false };

  expectNone(
    "existing extensionless script path",
    checkPaths(root, topic("`script/ci/exists`"), noIgnore).findings,
  );
  expectFinding(
    "missing extensionless script path",
    checkPaths(root, topic("`script/ci/missing`"), noIgnore).findings,
    /script\/ci\/missing/,
  );
  expectFinding(
    "missing kernel path",
    checkPaths(root, topic("`engines/core/lib/missing.rb`"), noIgnore).findings,
    /engines\/core\/lib\/missing/,
  );
  expectNone(
    "gitignored path",
    checkPaths(root, topic("`script/ci/ignored`"), { ignored: () => true }).findings,
  );
  expectNone(
    "illustrative engine path in a topic",
    checkPaths(root, topic("`engines/example_orders/missing.rb`"), noIgnore).findings,
  );
  expectNone(
    "engine-relative config path in a topic",
    checkPaths(root, topic("`config/locales/en.yml`"), noIgnore).findings,
  );
  expectFinding(
    "instruction missing config path",
    checkPaths(root, instruction("`config/missing.yml`"), noIgnore).findings,
    /config\/missing.yml/,
  );
  expectNone(
    "payload .github path",
    checkPaths(root, topic("`.github/workflows/pull_request.yml`"), noIgnore).findings,
  );
  expectFinding(
    "missing payload .github path",
    checkPaths(root, topic("`.github/workflows/missing.yml`"), noIgnore).findings,
    /missing.yml/,
  );
} finally {
  rmSync(root, { recursive: true, force: true });
}

// AI instruction entries and skill front matter.
const aiRoot = mkdtempSync(join(tmpdir(), "rafelo-docs-ai-"));
try {
  const skill = (directory: string, text: string) => {
    mkdirSync(join(aiRoot, ".opencode", "skills", directory), { recursive: true });
    writeFileSync(join(aiRoot, ".opencode", "skills", directory, "SKILL.md"), text);
  };
  mkdirSync(join(aiRoot, "docs"), { recursive: true });
  writeFileSync(join(aiRoot, "docs", "opencode.md"), "Use `bin/ci`.\n");
  skill("good", "---\nname: good\ndescription: Use when checking a skill.\n---\n\n# Good\n");

  const config = {
    ai_instruction_files: [".opencode/skills/good/SKILL.md", "docs/opencode.md"],
  };
  const valid = aiFiles(aiRoot, config);
  expectNone("valid skill entry", valid.findings);
  expect("valid skill file is read", valid.files.includes(".opencode/skills/good/SKILL.md"));

  const missing = aiFiles(aiRoot, {
    ...config,
    ai_instruction_files: [".opencode/skills/missing/SKILL.md"],
  });
  expectFinding("missing skill entry", missing.findings, /matches no file/);

  skill("bad", "---\nname: other\ndescription: Use when checking a skill.\n---\n\n# Bad\n");
  expectFinding(
    "skill name mismatch",
    aiFiles(aiRoot, { ai_instruction_files: [".opencode/skills/bad/SKILL.md"] }).findings,
    /name must match/,
  );

  skill("nodesc", "---\nname: nodesc\n---\n\n# No description\n");
  expectFinding(
    "skill without a description",
    aiFiles(aiRoot, {
      ai_instruction_files: [".opencode/skills/nodesc/SKILL.md"],
    }).findings,
    /missing a description/,
  );

  skill("nofront", "# No front matter\n");
  expectFinding(
    "skill without front matter",
    aiFiles(aiRoot, {
      ai_instruction_files: [".opencode/skills/nofront/SKILL.md"],
    }).findings,
    /no front matter/,
  );

  skill(
    "unlisted",
    "---\nname: unlisted\ndescription: Use when checking a skill.\n---\n\n# Unlisted\n",
  );
  expectFinding(
    "unlisted skill",
    aiFiles(aiRoot, config).findings,
    /skill is not listed in ai_instruction_files/,
  );
  for (const directory of ["unlisted", "bad", "nodesc", "nofront"]) {
    rmSync(join(aiRoot, ".opencode", "skills", directory), { recursive: true, force: true });
  }

  skill("oo-pack", "---\nname: oo-pack\ndescription: Use when checking a skill.\n---\n\n# Pack\n");
  expectNone("unlisted pack skill", aiFiles(aiRoot, config).findings);
} finally {
  rmSync(aiRoot, { recursive: true, force: true });
}

// Pack-versus-project conflicts.
const packRows = PACK_CONFLICTS.map((name) => `| \`${name}\` | rule | resolution |`).join("\n");
const packSection = `## Pack versus project\n\n${packRows}\n\n## Next\n`;
expectNone("pack conflicts section", checkPackConflicts(packSection));
expectFinding(
  "missing pack conflict",
  checkPackConflicts(packSection.replace(`\`${PACK_CONFLICTS[0]}\``, "")),
  /resolved pack conflict is missing/,
);
expectFinding("missing pack section", checkPackConflicts("# Guide\n"), /section is missing/);

// Generated table.
const start = "<!-- generated:envelope:start -->";
const end = "<!-- generated:envelope:end -->";
const stale = `# Contracts\n\n${start}\n| Field | Shape | Required |\n| --- | --- | --- |\n| stale | table | no |\n${end}\n`;
expectFinding("stale generated table", checkGenerated(stale), /stale; run npm run docs:generate/);
const fresh = rewriteGenerated(stale);
expectNone("fresh generated table", checkGenerated(fresh));
expect("fresh table contains the auth field", fresh.includes("`auth`"));

// Held-back table (WF-06).
const heldBackPkg = {
  dependencies: { react: "19.3.1" },
  devDependencies: { "react-dom": "19.3.1", vite: "8.3.7" },
};
const heldBackConfig = {
  packageRules: [
    { groupName: "react", matchPackageNames: ["react", "react-dom"] },
    {
      description: "React 20 is not supported",
      matchPackageNames: ["react", "react-dom"],
      allowedVersions: "<20",
    },
  ],
};
const heldBack = heldBackRows(heldBackConfig, heldBackPkg);
expectNone("valid held-back rules", heldBack.findings);
const heldBackMarkup = `<!-- generated:held-back:start -->\n${heldBackTable(heldBack.rows ?? [])}\n<!-- generated:held-back:end -->\n`;
expectNone(
  "fresh held-back table",
  checkHeldBack(heldBackMarkup, heldBackTable(heldBack.rows ?? [])),
);
expectFinding(
  "stale held-back table",
  checkHeldBack(
    heldBackMarkup.replace("React 20 is not supported", "old reason"),
    heldBackTable(heldBack.rows ?? []),
  ),
  /held-back table is stale/,
);
expect(
  "held-back table names the pinned version",
  heldBackTable(heldBack.rows ?? []).includes("| `react`, `react-dom` | 19.3.1 |"),
);
expectFinding(
  "held-back rule without a description",
  heldBackRows(
    { packageRules: [{ matchPackageNames: ["react"], allowedVersions: "<20" }] },
    heldBackPkg,
  ).findings,
  /without a description/,
);
expectFinding(
  "held-back rule without matchPackageNames",
  heldBackRows({ packageRules: [{ description: "why", allowedVersions: "<20" }] }, heldBackPkg)
    .findings,
  /without matchPackageNames/,
);
const heldBackRewritten = rewriteHeldBack(
  heldBackMarkup,
  "| Package | Pinned | Why |\n| --- | --- | --- |\n| `react` | 19.3.1 | why |",
);
expect(
  "held-back rewrite keeps the markers",
  heldBackRewritten.includes("<!-- generated:held-back:start -->") &&
    heldBackRewritten.includes("| `react` | 19.3.1 | why |"),
);

// CT-01 table parity (CT-09).
const ct01 = readFileSync("docs/architecture/04_contracts.md", "utf8");
expectNone("CT-01 table matches the shared props schema", checkEnvelopeTable(ct01));
expectFinding(
  "CT-01 table missing app.signInHref",
  checkEnvelopeTable(ct01.replace("`signInHref`", "the sign-in page")),
  /missing app\.signInHref/,
);
expectFinding(
  "CT-01 table missing a top-level shared key",
  checkEnvelopeTable(ct01.replace("| `trace` |", "| `traceX` |")),
  /missing shared key trace/,
);
expectFinding(
  "CT-01 table naming an unknown shared key",
  checkEnvelopeTable(ct01.replace("| `trace` |", "| `traceX` |")),
  /unknown shared key traceX/,
);

if (failures > 0) {
  console.error(`docs:canary: checked ${cases} case(s); failures=${failures}`);
  process.exit(1);
}
console.log(`docs:canary: checked ${cases} case(s); failures=0`);
