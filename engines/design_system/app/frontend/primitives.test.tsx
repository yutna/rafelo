import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { ComboBox } from "./combobox";
import { Menu } from "./menu";
import { Select } from "./select";
import { Tabs } from "./tabs";

const items = [
  { id: "open", label: "Open" },
  { id: "paid", label: "Paid" },
];

describe("design-system primitives", () => {
  it("selects an option from the select", async () => {
    const onSelectionChange = vi.fn();
    render(
      <Select testId="status" label="Status" items={items} onSelectionChange={onSelectionChange} />,
    );

    await userEvent.click(screen.getByTestId("status"));
    await userEvent.click(await screen.findByTestId("status.option.paid"));

    expect(onSelectionChange).toHaveBeenCalledWith("paid");
  });

  it("runs the chosen menu action", async () => {
    const onAction = vi.fn();
    render(<Menu testId="actions" label="Actions" items={items} onAction={onAction} />);

    await userEvent.click(screen.getByTestId("actions"));
    await userEvent.click(await screen.findByTestId("actions.item.open"));

    expect(onAction).toHaveBeenCalledWith("open");
  });

  it("selects an option from the combobox", async () => {
    const onSelectionChange = vi.fn();
    render(
      <ComboBox testId="owner" label="Owner" items={items} onSelectionChange={onSelectionChange} />,
    );

    await userEvent.click(screen.getByTestId("owner.toggle"));
    await userEvent.click(await screen.findByTestId("owner.option.open"));

    expect(onSelectionChange).toHaveBeenCalledWith("open");
  });

  it("reports the selected tab and renders its panel", async () => {
    const onSelectionChange = vi.fn();
    const { rerender } = render(
      <Tabs
        testId="sections"
        label="Sections"
        tabs={[
          { id: "one", label: "One", content: "First" },
          { id: "two", label: "Two", content: "Second" },
        ]}
        selectedKey="one"
        onSelectionChange={onSelectionChange}
      />,
    );

    expect(screen.getByTestId("sections.panel.one")).toHaveTextContent("First");

    await userEvent.click(screen.getByTestId("sections.tab.two"));

    expect(onSelectionChange).toHaveBeenCalledWith("two");

    rerender(
      <Tabs
        testId="sections"
        label="Sections"
        tabs={[
          { id: "one", label: "One", content: "First" },
          { id: "two", label: "Two", content: "Second" },
        ]}
        selectedKey="two"
        onSelectionChange={onSelectionChange}
      />,
    );

    expect(screen.getByTestId("sections.panel.two")).toHaveTextContent("Second");
  });
});
