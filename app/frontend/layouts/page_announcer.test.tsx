import { act, cleanup, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";

import { PageAnnouncer } from "./page_announcer";

function loadPage(path: string, heading: string) {
  document.body.innerHTML = `<main><h1>${heading}</h1></main>`;
  window.history.replaceState({}, "", path);
}

function setHeading(heading: string) {
  screen.getByRole("heading", { level: 1 }).textContent = heading;
}

function navigate(url: string, type = "visit") {
  act(() => {
    document.dispatchEvent(
      new CustomEvent("inertia:navigate", { detail: { page: { url }, type } }),
    );
  });
}

async function flushAnimationFrame() {
  await act(async () => {
    await new Promise((resolve) => setTimeout(resolve, 0));
  });
}

describe("PageAnnouncer", () => {
  afterEach(() => {
    cleanup();
    document.body.innerHTML = "";
    document.title = "";
    window.history.replaceState({}, "", "/");
  });

  it("stays silent on the initial page", async () => {
    loadPage("/en/invoices/1", "Invoice 1");
    render(<PageAnnouncer />);

    navigate("/en/invoices/1", "initial");
    await flushAnimationFrame();

    expect(screen.getByTestId("page.announcer")).toHaveClass("sr-only");
    expect(screen.getByTestId("page.announcer")).toHaveTextContent("");
    const heading = screen.getByRole("heading", { level: 1 });
    expect(heading).not.toHaveFocus();
  });

  it("announces the new record and focuses its heading", async () => {
    loadPage("/en/invoices/1", "Invoice 1");
    document.title = "Invoice 1";
    render(<PageAnnouncer />);

    setHeading("Invoice 2");
    window.history.pushState({}, "", "/en/invoices/2");
    navigate("/en/invoices/2");

    await waitFor(() =>
      expect(screen.getByTestId("page.announcer")).toHaveTextContent("Invoice 2"),
    );
    expect(screen.getByRole("heading", { level: 1 })).toHaveFocus();
    expect(document.title).toBe("Invoice 1");
  });

  it("announces a Back navigation", async () => {
    loadPage("/en/invoices/2", "Invoice 2");
    render(<PageAnnouncer />);

    setHeading("Invoice 1");
    navigate("/en/invoices/1", "history");

    await waitFor(() =>
      expect(screen.getByTestId("page.announcer")).toHaveTextContent("Invoice 1"),
    );
    expect(screen.getByRole("heading", { level: 1 })).toHaveFocus();
  });

  it("announces the show page after a create redirect", async () => {
    loadPage("/en/orders/new", "New order");
    render(<PageAnnouncer />);

    setHeading("Order 42");
    window.history.pushState({}, "", "/en/orders/42");
    navigate("/en/orders/42");

    await waitFor(() => expect(screen.getByTestId("page.announcer")).toHaveTextContent("Order 42"));
    expect(screen.getByRole("heading", { level: 1 })).toHaveFocus();
  });

  it("does not announce or focus when a filter keeps the same path", async () => {
    loadPage("/en/orders", "Orders");
    render(<PageAnnouncer />);

    setHeading("Paid orders");
    window.history.pushState({}, "", "/en/orders?status=paid");
    navigate("/en/orders?status=paid");

    await flushAnimationFrame();

    expect(screen.getByTestId("page.announcer")).toHaveTextContent("");
    expect(screen.getByRole("heading", { level: 1 })).not.toHaveFocus();
  });

  it("falls back to the document title when the page has no heading", async () => {
    loadPage("/en/invoices/1", "Invoice 1");
    document.title = "Invoice 1";
    render(<PageAnnouncer />);

    screen.getByRole("heading", { level: 1 }).remove();
    document.title = "Invoice 2";
    navigate("/en/invoices/2");

    await waitFor(() =>
      expect(screen.getByTestId("page.announcer")).toHaveTextContent("Invoice 2"),
    );
  });
});
