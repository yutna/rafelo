import { Button, Chart, Deferred, Link, Skeleton, formatNumber, useLocale } from "@design_system/public";
import { router } from "@inertiajs/react";

import { t } from "../../i18n";

type Order = {
  id: string;
  number: string;
  customer: { id: string; name: string; tier: string };
  status: string;
  total: { minor: number; currency: string; exponent: number };
  issuedOn: string;
  href: string;
};

type Props = {
  items: Order[];
  newHref: string | null;
  exportPath: string;
  filterHrefs: { label: string; href: string; current: boolean }[];
  previousHref: string | null;
  nextHref: string | null;
  chart?: { series: Record<string, unknown>[] };
  can: Record<string, { allowed: boolean; reason: string | null }>;
};

export function OrdersScreen({
  items,
  newHref,
  exportPath,
  filterHrefs,
  previousHref,
  nextHref,
  chart,
  can,
}: Props) {
  const { locale } = useLocale();
  return (
    <section className="mx-auto max-w-5xl px-6 py-16">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-display font-semibold">{t("orders.title")}</h1>
          <p className="mt-1 text-slate-600">{t("orders.subtitle")}</p>
        </div>
        <div className="flex gap-2">
          {can["order.create"]?.allowed && newHref ? (
            <Link href={newHref} className="rounded-card bg-primary px-4 py-2 text-white" >
              <span data-testid="example_orders.orders.index.new">{t("orders.new")}</span>
            </Link>
          ) : null}
          {can["order.export"]?.allowed ? (
            <Button testId="example_orders.orders.index.export" variant="secondary" onPress={() => router.post(exportPath)}>
              {t("orders.export")}
            </Button>
          ) : null}
        </div>
      </div>

      <nav aria-label={t("orders.filter")} className="mt-6 flex flex-wrap gap-2">
        {filterHrefs.map((filter) => (
          <Link key={filter.label} href={filter.href} className={filter.current ? "font-semibold underline" : "underline"}>
            <span data-testid={`example_orders.orders.index.filter.${filter.label}`}>{filter.label}</span>
          </Link>
        ))}
      </nav>

      {items.length === 0 ? <p className="mt-6">{t("orders.empty")}</p> : (
        <ul className="mt-6 divide-y divide-slate-200" data-testid="example_orders.orders.index.list">
          {items.map((order) => (
            <li key={order.id} className="py-3">
              <Link href={order.href} className="flex flex-wrap items-center justify-between gap-2">
                <span data-testid={`example_orders.orders.index.row.${order.id}`}>
                  {order.number} · {order.customer.name}
                </span>
                <span>{order.status} · {order.total.currency} {formatNumber(order.total.minor / 100, locale)}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}

      <nav aria-label="Pagination" className="mt-6 flex gap-4">
        {previousHref ? <Link href={previousHref}>Previous</Link> : null}
        {nextHref ? <Link href={nextHref}>Next</Link> : null}
      </nav>

      <div className="mt-10">
        <Deferred data="data.chart" fallback={<Skeleton testId="example_orders.orders.index.chart-loading" />}>
          {chart ? <Chart testId="example_orders.orders.index.chart" option={chart} ariaLabel={t("orders.title")} /> : null}
        </Deferred>
      </div>
    </section>
  );
}
