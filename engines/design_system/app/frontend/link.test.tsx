import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

vi.mock("@inertiajs/react", () => ({
  Link: ({ href, children, ...props }: { href: string; children: React.ReactNode }) => (
    <a href={href} data-inertia="true" {...props}>
      {children}
    </a>
  ),
}));

import { Link } from "./link";

describe("Link", () => {
  it("routes an app path through Inertia with its test id", () => {
    render(
      <Link testId="orders.link" href="/en/orders">
        Orders
      </Link>,
    );

    const link = screen.getByTestId("orders.link");
    expect(link).toHaveAttribute("href", "/en/orders");
    expect(link).toHaveAttribute("data-inertia", "true");
  });

  it("renders an absolute URL as a plain anchor", () => {
    render(
      <Link testId="external.link" href="https://example.test/help">
        Help
      </Link>,
    );

    const link = screen.getByTestId("external.link");
    expect(link.tagName).toBe("A");
    expect(link).toHaveAttribute("href", "https://example.test/help");
    expect(link).not.toHaveAttribute("data-inertia");
  });

  it("does not render an unsafe URL as a link", () => {
    render(
      <Link testId="unsafe.link" href={"javascript:alert(1)"}>
        Unsafe
      </Link>,
    );

    expect(screen.getByTestId("unsafe.link").tagName).toBe("SPAN");
  });
});
