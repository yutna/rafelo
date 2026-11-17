import { render } from "@testing-library/react";
import * as React from "react";
import { describe, expect, it } from "vitest";

function Widget() {
  const [value] = React.useState(0);
  return <div>{value}</div>;
}

describe("Widget", () => {
  it("renders", () => {
    expect(render(<Widget />)).toBeTruthy();
  });
});
