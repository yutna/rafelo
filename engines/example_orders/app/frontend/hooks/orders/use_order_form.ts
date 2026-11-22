import type { Href } from "@design_system/public";

import { focusFirstError } from "@design_system/public";
import {
  initialOrderForm,
  orderFormPayload,
  type OrderFormValues,
} from "@example_orders/forms/orders/order_form";
import { useForm } from "@inertiajs/react";
import { useRef } from "react";

type Options = {
  mode: "create" | "edit";
  action: Href;
  meta: { formToken: string };
  errors: Record<string, string>;
  initial?: Partial<OrderFormValues>;
  version?: number;
};

export function useOrderForm({ mode, action, meta, errors, initial, version }: Options) {
  const form = useForm<OrderFormValues>(initialOrderForm(initial));
  const formRef = useRef<HTMLFormElement>(null);
  const formErrors: Record<string, string> = { ...errors, ...form.errors };

  function submit() {
    form.transform((values) => ({
      ...orderFormPayload(values, mode === "edit" ? version : undefined),
      token: meta.formToken,
    }));
    const options = {
      onError: () => setTimeout(() => focusFirstError(formRef.current ?? undefined), 0),
    };
    if (mode === "edit") form.patch(action, options);
    else form.post(action, options);
  }

  return { form, formRef, formErrors, submit };
}
