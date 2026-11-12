import { describe, expect, it } from "vitest";

import { appMetadata } from "./app_metadata";

describe("appMetadata", () => {
  it("names the application", () => {
    expect(appMetadata.name).toBe("Rafelo");
  });
});
