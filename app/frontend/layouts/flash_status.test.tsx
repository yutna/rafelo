import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

const inertia = vi.hoisted(() => ({
  flash: {} as Record<string, unknown>,
}));

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({ url: "/en", flash: inertia.flash }),
}));

import { FlashStatus } from "./flash_status";

describe("FlashStatus", () => {
  beforeEach(() => {
    inertia.flash = {};
    vi.spyOn(console, "error").mockImplementation(() => {});
  });

  it("renders a notice as a status", () => {
    inertia.flash = { notice: "Saved" };

    render(<FlashStatus />);

    expect(screen.getByTestId("page.flash")).toHaveTextContent("Saved");
    expect(screen.getByTestId("page.flash.notice")).toBeInTheDocument();
  });

  it("renders a notice beside an alert", () => {
    inertia.flash = { alert: "Failed", notice: "Saved" };

    render(<FlashStatus />);

    expect(screen.getByTestId("page.flash.alert")).toHaveTextContent("Failed");
    expect(screen.getByTestId("page.flash.notice")).toHaveTextContent("Saved");
  });

  it("clears the notice on later renders", () => {
    inertia.flash = { notice: "Saved" };
    const { rerender } = render(<FlashStatus />);
    expect(screen.getByTestId("page.flash.notice")).toHaveTextContent("Saved");

    inertia.flash = {};
    rerender(<FlashStatus />);
    expect(screen.getByTestId("page.flash")).toBeEmptyDOMElement();

    rerender(<FlashStatus />);
    expect(screen.getByTestId("page.flash")).toBeEmptyDOMElement();
  });

  it("throws on a flash payload outside the schema", () => {
    inertia.flash = { notice: 42 };

    expect(() => render(<FlashStatus />)).toThrow();
  });
});
