import { describe, it, test } from "vitest";

describe("forms", () => {
  it.skip("a", () => {}); // #123
  it.todo("b"); // #123
  it.skipIf(true)("c", () => {}); // #123
  test.fixme("d", () => {}); // #123
  test.describe.skip("e", () => {}); // #123
  test.describe.fixme("f", () => {}); // #123
  xit("g", () => {}); // #123
  xdescribe("h", () => {}); // #123
  xcontext("i", () => {}); // #123
  xspecify("j", () => {}); // #123
  xexample("k", () => {}); // #123
  skip(); // #123
  void pending; // #123
  export const metadata = { pending: true }; // #123
  export const options = { prosopite: false }; // #123
  Prosopite.pause(); // #123
});
