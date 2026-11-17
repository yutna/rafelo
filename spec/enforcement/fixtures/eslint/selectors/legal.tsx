import { screen } from "@testing-library/react";
import { expect } from "vitest";

export function check() {
  expect(screen.getByRole("heading", { level: 1 })).toBeTruthy();
  expect(screen.getByTestId("page.heading")).toBeTruthy();
}
