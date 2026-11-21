import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { Button } from "./button";
import { ConfirmDialog } from "./confirm_dialog";
import { EmptyState } from "./empty_state";
import { FilterBar } from "./filter_bar";

describe("design-system composites", () => {
  it("renders the filter bar with a search field and its filters", async () => {
    const onSearchChange = vi.fn();
    render(
      <FilterBar
        testId="filters"
        label="Filters"
        searchLabel="Search"
        searchValue=""
        onSearchChange={onSearchChange}
      >
        <span data-testid="filters.status">Status</span>
      </FilterBar>,
    );

    expect(screen.getByTestId("filters.status")).toBeVisible();

    await userEvent.type(screen.getByTestId("filters.search"), "ada");

    expect(onSearchChange).toHaveBeenCalled();
  });

  it("confirms and cancels through the confirm dialog", async () => {
    const onConfirm = vi.fn();
    const onCancel = vi.fn();
    const { rerender } = render(
      <ConfirmDialog
        testId="confirm"
        title="Delete item?"
        message="This cannot be undone."
        confirmLabel="Delete"
        cancelLabel="Cancel"
        open
        onConfirm={onConfirm}
        onCancel={onCancel}
      />,
    );

    await userEvent.click(screen.getByTestId("confirm.confirm"));
    expect(onConfirm).toHaveBeenCalledTimes(1);

    rerender(
      <ConfirmDialog
        testId="confirm"
        title="Delete item?"
        message="This cannot be undone."
        confirmLabel="Delete"
        cancelLabel="Cancel"
        open
        onConfirm={onConfirm}
        onCancel={onCancel}
      />,
    );

    await userEvent.click(screen.getByTestId("confirm.cancel"));
    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  it("renders an empty state with its action", () => {
    render(
      <EmptyState
        testId="empty"
        title="Nothing here"
        description="No records to show."
        action={<Button testId="empty.action">Create</Button>}
      />,
    );

    expect(screen.getByTestId("empty")).toHaveTextContent("Nothing here");
    expect(screen.getByTestId("empty.action")).toBeVisible();
  });
});
