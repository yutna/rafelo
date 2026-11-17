import { screen } from "@testing-library/react";

function getByRole(role: string, options: { name: string }) {
  return [role, options];
}

export function check() {
  screen.getByText("Save");
  screen.findByText("Save");
  screen.queryByLabelText("Save");
  screen.getByLabel("Save");
  screen.getByPlaceholder("Save");
  screen.queryAllByPlaceholderText("Save");
  screen.getByDisplayValue("Save");
  screen.getByTitle("Save");
  screen.getByAltText("Save");
  screen.locator(".save");
  screen.querySelectorAll(".save");
  screen.getByRole("button", { name: "Save" });
  getByRole("heading", { name: "Title" });
  return null;
}
