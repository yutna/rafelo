import type { chartSchema } from "@core/contracts/page_props.schema";
import type { Href } from "@design_system/public";
import type { OrderListRow } from "@example_orders/components/orders/list.types";
import type { z } from "zod";

import { Button, Chart, Deferred, Link, Skeleton } from "@design_system/public";
import { OrdersList } from "@example_orders/components/orders/list";
import { useOrderExport } from "@example_orders/hooks/orders/use_order_export";
import { useOrdersTranslation } from "@example_orders/i18n";

import { ordersChartOption } from "./chart";

type Props = {
  items: OrderListRow[];
  newHref: Href | null;
  exportHref: Href;
  filterHrefs: { key: string; label: string; href: Href; current: boolean }[];
  previousHref: Href | null;
  nextHref: Href | null;
  chart?: z.infer<typeof chartSchema>;
  can: Record<string, { allowed: boolean; reason: string | null }>;
  meta: { formToken: string };
};

export function OrdersIndexContainer({
  items,
  newHref,
  exportHref,
  filterHrefs,
  previousHref,
  nextHref,
  chart,
  can,
  meta,
}: Props) {
  const t = useOrdersTranslation();
  const exportOrders = useOrderExport();
  return (
    <section className="mx-auto max-w-5xl px-6 py-16">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1
            className="text-display font-semibold"
            data-testid="example_orders.orders.index.title"
          >
            {t("orders.title")}
          </h1>
          <p className="mt-1 text-slate-600">{t("orders.subtitle")}</p>
        </div>
        <div className="flex gap-2">
          {can["order.create"]?.allowed && newHref ? (
            <Link
              testId="example_orders.orders.index.new.link"
              href={newHref}
              className="rounded-card bg-primary px-4 py-2 text-white"
            >
              <span data-testid="example_orders.orders.index.new">{t("orders.new")}</span>
            </Link>
          ) : null}
          {can["order.export"]?.allowed ? (
            <Button
              testId="example_orders.orders.index.export"
              variant="secondary"
              onPress={() => exportOrders(exportHref, meta.formToken)}
            >
              {t("orders.export")}
            </Button>
          ) : null}
        </div>
      </div>

      <nav aria-label={t("orders.filter")} className="mt-6 flex flex-wrap gap-2">
        {filterHrefs.map((filter) => (
          <Link
            key={filter.key}
            testId={`example_orders.orders.index.filter.${filter.key}.link`}
            href={filter.href}
            className={filter.current ? "font-semibold underline" : "underline"}
          >
            <span data-testid={`example_orders.orders.index.filter.${filter.key}`}>
              {filter.label}
            </span>
          </Link>
        ))}
      </nav>

      <OrdersList items={items} emptyLabel={t("orders.empty")} />

      <nav aria-label={t("orders.pagination")} className="mt-6 flex gap-4">
        {previousHref ? (
          <Link testId="example_orders.orders.index.previous.link" href={previousHref}>
            {t("orders.previous")}
          </Link>
        ) : null}
        {nextHref ? (
          <Link testId="example_orders.orders.index.next.link" href={nextHref}>
            {t("orders.next")}
          </Link>
        ) : null}
      </nav>

      <div className="mt-10">
        <Deferred
          data="data.chart"
          fallback={<Skeleton testId="example_orders.orders.index.chart-loading" />}
        >
          {chart ? (
            <Chart
              testId="example_orders.orders.index.chart"
              option={ordersChartOption(chart)}
              ariaLabel={t("orders.title")}
              description={t("orders.chart_summary")}
            />
          ) : null}
        </Deferred>
      </div>
    </section>
  );
}
