import { Link, formatMoney, useLocale } from "@design_system/public";

import type { OrderListRow } from "./list.types";

export function OrdersList({ items, emptyLabel }: { items: OrderListRow[]; emptyLabel: string }) {
  const { locale } = useLocale();

  if (items.length === 0) {
    return (
      <p className="mt-6" data-testid="example_orders.orders.index.empty">
        {emptyLabel}
      </p>
    );
  }

  return (
    <ul className="mt-6 divide-y divide-slate-200" data-testid="example_orders.orders.index.list">
      {items.map((order) => (
        <li key={order.id} className="py-3">
          <Link
            testId={`example_orders.orders.index.row.${order.id}.link`}
            href={order.href}
            className="flex flex-wrap items-center justify-between gap-2"
          >
            <span data-testid={`example_orders.orders.index.row.${order.id}`}>
              {order.number} · {order.customer.name}
            </span>
            <span>
              {order.status} ·{" "}
              {formatMoney(order.total.minor, order.total.currency, order.total.exponent, locale)}
            </span>
          </Link>
        </li>
      ))}
    </ul>
  );
}
