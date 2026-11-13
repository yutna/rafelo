import { useForm } from "@inertiajs/react";
import { Button, Link } from "@design_system/public";

import { OrderFormFields } from "../../components/orders/form";
import { t } from "../../i18n";

type Props = {
  order: { id: string; number: string; customerName: string; status: string; version: number };
  updatePath: string;
  showPath: string;
  meta: { formToken: string };
  errors: Record<string, string>;
};

export function OrdersEditScreen({ order, updatePath, showPath, meta, errors }: Props) {
  const form = useForm({ customerName: order.customerName, status: order.status });

  return (
    <section className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-display font-semibold">{t("orders.edit")}</h1>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          form.transform((data) => ({ ...data, token: meta.formToken, version: order.version }));
          form.patch(updatePath);
        }}
        className="mt-6 space-y-4"
      >
        <OrderFormFields
          customerName={form.data.customerName}
          status={form.data.status}
          errors={errors}
          onCustomerNameChange={(value) => form.setData("customerName", value)}
          onStatusChange={(value) => form.setData("status", value)}
        />
        <div className="flex items-center gap-4">
          <Button testId="example_orders.orders.edit.submit" type="submit" isDisabled={form.processing}>
            {t("orders.save")}
          </Button>
          <Link href={showPath}>
            <span data-testid="example_orders.orders.edit.back">{t("orders.title")}</span>
          </Link>
        </div>
      </form>
    </section>
  );
}
