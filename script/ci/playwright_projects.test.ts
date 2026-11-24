import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, it } from "vitest";

import { engineE2eProjects, hasSpecFiles } from "./playwright_projects.mts";

const roots: string[] = [];

function fixture(): string {
  const root = mkdtempSync(join(tmpdir(), "rafelo-e2e-projects-"));
  roots.push(root);
  return root;
}

afterEach(() => {
  for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true });
});

describe("engine e2e projects", () => {
  it("skips a directory that holds only the generated .keep", () => {
    const root = fixture();
    mkdirSync(join(root, "customers", "e2e"), { recursive: true });
    writeFileSync(join(root, "customers", "e2e", ".keep"), "");

    expect(hasSpecFiles(join(root, "customers", "e2e"))).toBe(false);
    expect(engineE2eProjects(root)).toEqual([]);
  });

  it("includes an engine whose spec sits below a subdirectory", () => {
    const root = fixture();
    mkdirSync(join(root, "orders", "e2e", "flows"), { recursive: true });
    writeFileSync(join(root, "orders", "e2e", "flows", "create.spec.ts"), "");

    expect(engineE2eProjects(root)).toEqual(["orders"]);
  });

  it("sorts several engines and ignores one without an e2e directory", () => {
    const root = fixture();
    for (const name of ["billing", "accounts"]) {
      mkdirSync(join(root, name, "e2e"), { recursive: true });
      writeFileSync(join(root, name, "e2e", "page.spec.ts"), "");
    }
    mkdirSync(join(root, "customers"), { recursive: true });

    expect(engineE2eProjects(root)).toEqual(["accounts", "billing"]);
  });
});
