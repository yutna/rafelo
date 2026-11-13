import { CustomerBadge } from "@example_customers/public/customer_badge";
import { Link, formatDate, formatNumber, useLocale } from "@design_system/public";

import { t } from "../../i18n";

type Props = {
  order: {
    id: string;
    number: string;
    customer: { id: string; name: string; tier: string };
    status: string;
    total: { minor: number; currency: string; exponent: number };
    issuedOn: string;
    version: number;
  };
  editHref: string;
  indexPath: string;
  can: Record<string, { allowed: boolean; reason: string | null }>;
};

export function OrderShowScreen({ order, editHref, indexPath, can }: Props) {
  const { locale, timeZone } = useLocale();
  return (
    <section className="mx-auto max-w-3xl px-6 py-16" data-testid="example_orders.orders.show.page">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-display font-semibold">{order.number}</h1>
        <CustomerBadge name={order.customer.name} tier={order.customer.tier} />
      </div>
      <dl className="mt-6 grid gap-3 sm:grid-cols-2">
        <div>
          <dt className="font-medium">{t("orders.status")}</dt>
          <dd data-testid="example_orders.orders.show.status">{order.status}</dd>
        </div>
        <div>
          <dt className="font-medium">{t("orders.total")}</dt>
          <dd data-testid="example_orders.orders.show.total">
            {formatNumber(order.total.minor / 100, locale)} {order.total.currency}
          </dd>
        </div>
        <div>
          <dt className="font-medium">{t("orders.issued_on")}</dt>
          <dd>{formatDate(order.issuedOn, locale, timeZone)}</dd>
        </div>
        <div>
          <dt className="font-medium">{t("orders.version")}</dt>
          <dd>{order.version}</dd>
        </div>
      </dl>
      <div className="mt-8 flex gap-4">
        {can["order.update"]?.allowed ? (
          <Link href={editHref}>
            <span data-testid="example_orders.orders.show.edit">{t("orders.edit")}</span>
          </Link>
        ) : null}
        <Link href={indexPath}>
          <span data-testid="example_orders.orders.show.back">{t("orders.title")}</span>
        </Link>
      </div>
    </section>
  );
}
