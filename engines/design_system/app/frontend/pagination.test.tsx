import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import i18next from "i18next";
import { beforeAll, describe, expect, it, vi } from "vitest";

import en from "./locales/en.json";
import { Pagination } from "./pagination";

beforeAll(async () => {
  await i18next.init({
    lng: "en",
    resources: { en: { design_system: en } },
    interpolation: { escapeValue: false },
  });
});

describe("Pagination", () => {
  it("renders the label and the offset status from the first render", () => {
    render(
      <Pagination
        testId="orders.pagination"
        label="Orders pages"
        previousLabel="Previous"
        nextLabel="Next"
        page={2}
        perPage={10}
        total={50}
        onPageChange={() => {}}
      />,
    );

    expect(screen.getByRole("navigation")).toHaveAccessibleName("Orders pages");
    expect(screen.getByTestId("orders.pagination.status")).toHaveTextContent("Page 2 of 5");
  });

  it("changes page and keeps focus at a boundary", async () => {
    const onPageChange = vi.fn();
    const { rerender } = render(
      <Pagination
        testId="orders.pagination"
        label="Orders pages"
        previousLabel="Previous"
        nextLabel="Next"
        page={2}
        perPage={10}
        total={50}
        onPageChange={onPageChange}
      />,
    );

    await userEvent.click(screen.getByTestId("orders.pagination.next"));
    expect(onPageChange).toHaveBeenLastCalledWith(3);

    rerender(
      <Pagination
        testId="orders.pagination"
        label="Orders pages"
        previousLabel="Previous"
        nextLabel="Next"
        page={5}
        perPage={10}
        total={50}
        onPageChange={onPageChange}
      />,
    );
    const next = screen.getByTestId("orders.pagination.next");
    await userEvent.click(next);

    expect(next).toHaveAttribute("aria-disabled", "true");
    expect(next).toHaveFocus();
    expect(onPageChange).toHaveBeenCalledTimes(1);
  });

  it("renders the cursor kind with its status and hrefs", async () => {
    const onNavigate = vi.fn();
    render(
      <Pagination
        kind="cursor"
        testId="orders.pagination"
        label="Orders pages"
        previousLabel="Previous"
        nextLabel="Next"
        previousHref={null}
        nextHref="/en/orders?cursor=2"
        onNavigate={onNavigate}
        status="Next page"
      />,
    );

    expect(screen.getByTestId("orders.pagination.status")).toHaveTextContent("Next page");
    expect(screen.getByTestId("orders.pagination.previous")).toHaveAttribute(
      "aria-disabled",
      "true",
    );

    await userEvent.click(screen.getByTestId("orders.pagination.next"));
    expect(onNavigate).toHaveBeenCalledWith("/en/orders?cursor=2");
  });
});
