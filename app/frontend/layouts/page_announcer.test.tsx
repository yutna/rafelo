import { act, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";

import { PageAnnouncer } from "./page_announcer";

describe("PageAnnouncer", () => {
  afterEach(() => {
    document.body.innerHTML = "";
    window.history.replaceState({}, "", "/");
  });

  it("stays silent on the initial page", () => {
    document.body.innerHTML = "<main><h1>Invoices</h1></main>";
    render(<PageAnnouncer />);

    expect(screen.getByTestId("page.announcer")).toHaveTextContent("");
    const heading = screen.getByRole("heading", { level: 1 });
    expect(heading).not.toHaveFocus();
  });

  it("announces and focuses a new path, including history", async () => {
    document.body.innerHTML = "<main><h1>Invoices</h1></main>";
    render(<PageAnnouncer />);
    window.history.pushState({}, "", "/en/invoices/2");

    act(() => {
      document.dispatchEvent(
        new CustomEvent("inertia:navigate", {
          detail: { page: { url: "/en/invoices/2" }, type: "history" },
        }),
      );
    });

    await waitFor(() => expect(screen.getByTestId("page.announcer")).toHaveTextContent("Invoices"));
    const heading = screen.getByRole("heading", { level: 1 });
    expect(heading).toHaveFocus();
  });
});
