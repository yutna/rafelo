import { readFileSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

import { appPathSchema } from "./app_path.schema";

describe("appPathSchema", () => {
  it("reads the same hostile fixture as the design system", () => {
    const fixture = JSON.parse(
      readFileSync(join(process.cwd(), "spec/fixtures/hostile_urls.json"), "utf8"),
    ) as string[];

    fixture.forEach((value) => expect(appPathSchema.safeParse(value).success).toBe(false));
    expect(appPathSchema.safeParse("/en/invoices/7").success).toBe(true);
  });
});
