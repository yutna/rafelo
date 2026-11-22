export const ORDER_STATUSES = ["open", "paid", "cancelled"] as const;

export type OrderStatus = (typeof ORDER_STATUSES)[number];

export type OrderTotal = Readonly<{
  minor: number;
  currency: string;
  exponent: number;
}>;

export type OrderCustomer = Readonly<{
  id: string;
  name: string;
  tier: string;
}>;

export type Order = Readonly<{
  id: string;
  number: string;
  customer: OrderCustomer;
  status: OrderStatus;
  total: OrderTotal;
  issuedOn: string;
  href: string;
}>;

export function isOrderStatus(value: string): value is OrderStatus {
  return (ORDER_STATUSES as readonly string[]).includes(value);
}
