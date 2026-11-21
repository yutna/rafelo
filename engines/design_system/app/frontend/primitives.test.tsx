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
  it("selects an option from the select and shows its label when uncontrolled", async () => {
    const onSelectionChange = vi.fn();
    render(
      <Select testId="status" label="Status" items={items} onSelectionChange={onSelectionChange} />,
    );

    await userEvent.click(screen.getByTestId("status"));
    await userEvent.click(await screen.findByTestId("status.option.paid"));

    expect(onSelectionChange).toHaveBeenCalledWith("paid");
    expect(screen.getByTestId("status")).toHaveTextContent("Paid");
  });

  it("shows the controlled selection in the select", () => {
    render(<Select testId="status" label="Status" items={items} selectedKey="open" />);

    expect(screen.getByTestId("status")).toHaveTextContent("Open");
  });

  it("runs the chosen menu action", async () => {
    const onAction = vi.fn();
    render(<Menu testId="actions" label="Actions" items={items} onAction={onAction} />);

    await userEvent.click(screen.getByTestId("actions"));
    await userEvent.click(await screen.findByTestId("actions.item.open"));

    expect(onAction).toHaveBeenCalledWith("open");
  });

  it("selects an option from the combobox and shows its label when uncontrolled", async () => {
    const onSelectionChange = vi.fn();
    render(
      <ComboBox testId="owner" label="Owner" items={items} onSelectionChange={onSelectionChange} />,
    );

    await userEvent.click(screen.getByTestId("owner.toggle"));
    await userEvent.click(await screen.findByTestId("owner.option.open"));

    expect(onSelectionChange).toHaveBeenCalledWith("open");
    expect(screen.getByTestId("owner")).toHaveValue("Open");
  });

  it("shows the controlled selection in the combobox", () => {
    render(<ComboBox testId="owner" label="Owner" items={items} selectedKey="paid" />);

    expect(screen.getByTestId("owner")).toHaveValue("Paid");
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
