import type { Href } from "@design_system/public";

import { Button, Link } from "@design_system/public";
import { OrderFormFields } from "@example_orders/components/orders/form";
import { useOrderForm } from "@example_orders/hooks/orders/use_order_form";
import { useOrdersTranslation } from "@example_orders/i18n";

type Props = {
  order: { id: string; number: string; customerName: string; status: string; version: number };
  updateHref: Href;
  showHref: Href;
  meta: { formToken: string };
  errors: Record<string, string>;
};

export function OrdersEditContainer({ order, updateHref, showHref, meta, errors }: Props) {
  const t = useOrdersTranslation();
  const { form, formRef, formErrors, submit } = useOrderForm({
    mode: "edit",
    action: updateHref,
    meta,
    errors,
    initial: order,
    version: order.version,
  });

  return (
    <section className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-display font-semibold">{t("orders.edit")}</h1>
      <form
        ref={formRef}
        onSubmit={(event) => {
          event.preventDefault();
          submit();
        }}
        className="mt-6 space-y-4"
      >
        <OrderFormFields
          customerName={form.data.customerName}
          status={form.data.status}
          baseError={formErrors.base}
          errors={formErrors}
          onCustomerNameChange={(value) => form.setData("customerName", value)}
          onStatusChange={(value) => form.setData("status", value)}
        />
        <div className="flex items-center gap-4">
          <Button
            testId="example_orders.orders.edit.submit"
            type="submit"
            isPending={form.processing}
          >
            {t("orders.save")}
          </Button>
          <Link testId="example_orders.orders.edit.back.link" href={showHref}>
            <span data-testid="example_orders.orders.edit.back">{t("orders.title")}</span>
          </Link>
        </div>
      </form>
    </section>
  );
}
