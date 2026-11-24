import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";

/** True when the directory holds at least one Playwright spec, nested or not. */
export function hasSpecFiles(directory: string): boolean {
  if (!existsSync(directory)) return false;

  return readdirSync(directory, { recursive: true, withFileTypes: true }).some(
    (entry) => entry.isFile() && entry.name.endsWith(".spec.ts"),
  );
}

/** Engine names with a non-empty e2e project, sorted for a stable config. */
export function engineE2eProjects(root = "engines"): string[] {
  if (!existsSync(root)) return [];

  return readdirSync(root, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && hasSpecFiles(join(root, entry.name, "e2e")))
    .map((entry) => entry.name)
    .sort();
}
