import { act, renderHook } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

const inertia = vi.hoisted(() => ({
  post: vi.fn(),
  patch: vi.fn(),
  transform: vi.fn(),
}));

vi.mock("@inertiajs/react", () => ({
  useForm: (data: Record<string, string>) => ({
    data,
    errors: {},
    processing: false,
    setData: vi.fn(),
    transform: (callback: (values: Record<string, string>) => Record<string, unknown>) => {
      inertia.transform(callback(data));
    },
    post: inertia.post,
    patch: inertia.patch,
  }),
}));

import { useOrderForm } from "./use_order_form";

describe("useOrderForm", () => {
  it("posts a create form with its token", () => {
    const { result } = renderHook(() =>
      useOrderForm({
        mode: "create",
        action: "/en/example_orders/orders",
        meta: { formToken: "token" },
        errors: {},
      }),
    );

    act(() => result.current.submit());

    expect(inertia.transform).toHaveBeenCalledWith(
      expect.objectContaining({ customerName: "", status: "open", token: "token" }),
    );
    expect(inertia.post).toHaveBeenCalledWith(
      "/en/example_orders/orders",
      expect.objectContaining({ onError: expect.any(Function) }),
    );
  });

  it("patches an edit form with its version and token", () => {
    const { result } = renderHook(() =>
      useOrderForm({
        mode: "edit",
        action: "/en/example_orders/orders/order-1",
        meta: { formToken: "token" },
        errors: {},
        initial: { customerName: "Ada", status: "paid" },
        version: 2,
      }),
    );

    act(() => result.current.submit());

    expect(inertia.transform).toHaveBeenCalledWith({
      customerName: "Ada",
      status: "paid",
      version: 2,
      token: "token",
    });
    expect(inertia.patch).toHaveBeenCalledWith(
      "/en/example_orders/orders/order-1",
      expect.objectContaining({ onError: expect.any(Function) }),
    );
  });
});
