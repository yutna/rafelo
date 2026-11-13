import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { PageAnnouncer } from "./page_announcer";

describe("PageAnnouncer", () => {
  it("keeps a live region without announcing the initial page", () => {
    document.body.innerHTML = '<main><h1>Invoices</h1></main>';
    render(<PageAnnouncer />);

    expect(screen.getByTestId("page.announcer")).toHaveTextContent("");
    expect(screen.getByRole("heading", { name: "Invoices" })).not.toHaveFocus();
  });
});
