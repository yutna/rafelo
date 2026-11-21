import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { Button } from "./button";

describe("Button", () => {
  it("keeps focus and ignores presses while submitting", async () => {
    const onPress = vi.fn();
    render(
      <Button testId="save" isPending onPress={onPress}>
        Save
      </Button>,
    );

    const button = screen.getByTestId("save");
    button.focus();

    expect(button).toHaveFocus();
    expect(button).toHaveAttribute("aria-disabled", "true");

    await userEvent.click(button);

    expect(onPress).not.toHaveBeenCalled();
    expect(button).toHaveFocus();
  });
});
