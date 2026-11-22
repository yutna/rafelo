export type OrderFormValues = Readonly<{
  customerName: string;
  status: string;
}>;

export function initialOrderForm(initial?: Partial<OrderFormValues>): OrderFormValues {
  return {
    customerName: initial?.customerName ?? "",
    status: initial?.status ?? "open",
  };
}

export function orderFormPayload(values: OrderFormValues, version?: number) {
  return {
    customerName: values.customerName,
    status: values.status,
    ...(version === undefined ? {} : { version }),
  };
}
