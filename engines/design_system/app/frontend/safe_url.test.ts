import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

import { hrefSchema, isSafeUrl } from "./safe_url";

describe("isSafeUrl", () => {
  it("accepts only http(s) and app-relative paths", () => {
    const fixture = JSON.parse(
      readFileSync(join(process.cwd(), "spec/fixtures/hostile_urls.json"), "utf8"),
    ) as string[];

    fixture.forEach((value) => expect(isSafeUrl(value)).toBe(false));
    expect(isSafeUrl("https://app.test/x")).toBe(true);
    expect(isSafeUrl("/en/invoices/7")).toBe(true);
  });

  it("types every URL prop with the safe URL schema", () => {
    const fixture = JSON.parse(
      readFileSync(join(process.cwd(), "spec/fixtures/hostile_urls.json"), "utf8"),
    ) as string[];

    fixture.forEach((value) => expect(hrefSchema.safeParse(value).success).toBe(false));
    expect(hrefSchema.safeParse("https://app.test/x").success).toBe(true);
    expect(hrefSchema.safeParse("/en/invoices/7").success).toBe(true);
  });
});
