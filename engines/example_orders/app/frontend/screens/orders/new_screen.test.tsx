import "@testing-library/jest-dom/vitest";
import { I18nProvider } from "@design_system/i18n_provider";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

const inertia = vi.hoisted(() => ({
  post: vi.fn(),
  setData: vi.fn(),
}));

vi.mock("@inertiajs/react", async () => {
  const { useState } = await import("react");

  return {
    Link: ({ href, children }: { href: string; children: React.ReactNode }) => (
      <a href={href}>{children}</a>
    ),
    useForm: (initial: Record<string, string>) => {
      const [data, setData] = useState(initial);

      return {
        data,
        errors: {},
        processing: false,
        setData: (key: string, value: string) =>
          setData((current) => ({ ...current, [key]: value })),
        transform: () => undefined,
        post: (_url: string, options?: { onError?: (errors: Record<string, string>) => void }) => {
          inertia.post(_url);
          options?.onError?.({});
        },
      };
    },
  };
});

import { OrdersNewScreen } from "./new_screen";

function renderScreen(errors: Record<string, string>) {
  return render(
    <I18nProvider locale="en" timeZone="UTC">
      <OrdersNewScreen
        createPath="/en/orders"
        indexPath="/en/orders"
        meta={{ formToken: "token" }}
        errors={errors}
      />
    </I18nProvider>,
  );
}

describe("OrdersNewScreen", () => {
  async function fillForm() {
    await userEvent.type(screen.getByTestId("example_orders.orders.form.customer"), "Ada");
    await userEvent.clear(screen.getByTestId("example_orders.orders.form.status"));
    await userEvent.type(screen.getByTestId("example_orders.orders.form.status"), "open");
  }

  it("focuses the base error summary after a failed submit", async () => {
    renderScreen({ base: "The order could not be saved." });
    await fillForm();

    await userEvent.click(screen.getByTestId("example_orders.orders.new.submit"));
    expect(inertia.post).toHaveBeenCalled();

    await waitFor(() =>
      expect(screen.getByTestId("example_orders.orders.form.base-error")).toHaveFocus(),
    );
  });

  it("focuses the first invalid field after a failed submit", async () => {
    renderScreen({ customerName: "can't be blank" });
    await fillForm();

    await userEvent.click(screen.getByTestId("example_orders.orders.new.submit"));

    await waitFor(() =>
      expect(screen.getByTestId("example_orders.orders.form.customer")).toHaveFocus(),
    );
  });
});
