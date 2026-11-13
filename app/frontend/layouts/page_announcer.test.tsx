import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({ url: "/en/invoices" }),
}));

import { PageAnnouncer } from "./page_announcer";

describe("PageAnnouncer", () => {
  it("announces the document title and focuses the main heading", () => {
    document.title = "Invoices";
    document.body.innerHTML = '<main><h1>Invoices</h1></main>';
    render(<PageAnnouncer />);

    expect(screen.getByTestId("page-announcer")).toHaveTextContent("Invoices");
    expect(screen.getByRole("heading", { name: "Invoices" })).toHaveFocus();
  });
});
