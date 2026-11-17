import { describe, it, test } from "vitest";

describe("forms", () => {
  it.skip("a", () => {});
  it.todo("b");
  it.skipIf(true)("c", () => {});
  test.fixme("d", () => {});
  test.describe.skip("e", () => {});
  test.describe.fixme("f", () => {});
  xit("g", () => {});
  xdescribe("h", () => {});
  xcontext("i", () => {});
  xspecify("j", () => {});
  xexample("k", () => {});
  skip();
  void pending;
  export const metadata = { pending: true };
  export const options = { prosopite: false };
  Prosopite.pause();
});
