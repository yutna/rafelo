import "@testing-library/jest-dom/vitest";
import { I18nProvider } from "@design_system/i18n_provider";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

const inertia = vi.hoisted(() => ({
  post: vi.fn(),
  setData: vi.fn(),
}));

vi.mock("@inertiajs/react", () => ({
  Link: ({ href, children }: { href: string; children: React.ReactNode }) => (
    <a href={href}>{children}</a>
  ),
  useForm: (data: Record<string, string>) => ({
    data,
    errors: {},
    processing: false,
    setData: inertia.setData,
    transform: () => undefined,
    post: (_url: string, options?: { onError?: (errors: Record<string, string>) => void }) => {
      inertia.post(_url);
      options?.onError?.({});
    },
  }),
}));

import { OrdersNewScreen } from "./new_screen";

function renderScreen(errors: Record<string, string>) {
  render(
    <I18nProvider locale="en" timeZone="UTC">
      <OrdersNewScreen
        createHref="/en/orders"
        indexHref="/en/orders"
        meta={{ formToken: "token" }}
        errors={errors}
      />
    </I18nProvider>,
  );
}

function submit() {
  fireEvent.submit(screen.getByTestId("example_orders.orders.new.submit").closest("form")!);
}

describe("OrdersNewScreen", () => {
  it("focuses the base error summary after a failed submit", async () => {
    renderScreen({ base: "The order could not be saved." });

    submit();

    expect(inertia.post).toHaveBeenCalled();
    await waitFor(() =>
      expect(screen.getByTestId("example_orders.orders.form.base-error")).toHaveFocus(),
    );
  });

  it("focuses the first invalid field after a failed submit", async () => {
    renderScreen({ customerName: "can't be blank" });

    submit();

    await waitFor(() =>
      expect(screen.getByTestId("example_orders.orders.form.customer")).toHaveFocus(),
    );
  });
});
