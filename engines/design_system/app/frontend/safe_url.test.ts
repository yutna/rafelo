import { readFileSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

import { isSafeUrl } from "./safe_url";

describe("isSafeUrl", () => {
  it("accepts only http(s) and app-relative paths", () => {
    const fixture = JSON.parse(
      readFileSync(join(process.cwd(), "spec/fixtures/hostile_urls.json"), "utf8"),
    ) as string[];

    fixture.forEach((value) => expect(isSafeUrl(value)).toBe(false));
    expect(isSafeUrl("https://app.test/x")).toBe(true);
    expect(isSafeUrl("/en/invoices/7")).toBe(true);
  });
});
