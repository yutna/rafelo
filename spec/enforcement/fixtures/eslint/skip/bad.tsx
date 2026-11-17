import { describe, it, test } from "vitest";

describe("forms", () => {
  it.skip("a", () => {});
  it("b", () => {}, { pending: true });
  test.describe.skip("c", () => {});
  test.fixme("d", () => {});
  it.todo("e");
});

xit("f", () => {});
