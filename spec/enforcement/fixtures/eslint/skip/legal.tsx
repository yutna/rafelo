import { describe, it, test } from "vitest";

describe("forms", () => {
  it.skip("a", () => {}); // #123
  it("b", () => {}, { pending: true }); // #123
  test.describe.skip("c", () => {}); // #123
  test.fixme("d", () => {}); // #123
  it.todo("e"); // #123
});

xit("f", () => {}); // #123
