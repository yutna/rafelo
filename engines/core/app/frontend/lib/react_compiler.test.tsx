import "@testing-library/jest-dom/vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { useEffect } from "react";
import { describe, expect, it, vi } from "vitest";

import { useUiState } from "./use_ui_state";

const onChildRender = vi.fn();

function Child() {
  onChildRender();
  return <span data-testid="react_compiler.child" />;
}

function Parent() {
  const [state, update] = useUiState({ count: 0 });

  useEffect(() => {
    if (state.count === 0) update({ count: 1 });
  }, [state.count, update]);

  return (
    <div>
      <span data-testid="react_compiler.count">{state.count}</span>
      <Child />
    </div>
  );
}

describe("React Compiler in Vitest", () => {
  it("keeps a child with unchanged props from re-rendering", async () => {
    onChildRender.mockClear();
    render(<Parent />);

    await waitFor(() => expect(screen.getByTestId("react_compiler.count")).toHaveTextContent("1"));

    expect(onChildRender).toHaveBeenCalledTimes(1);
  });
});
