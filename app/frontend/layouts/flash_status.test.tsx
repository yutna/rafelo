import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({ url: "/en", flash: { notice: "Saved" } }),
}));

import { FlashStatus } from "./flash_status";

describe("FlashStatus", () => {
  it("renders the page-level flash once as a status", () => {
    render(<FlashStatus />);

    expect(screen.getByRole("status")).toHaveTextContent("Saved");
  });
});
