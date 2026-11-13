import { useForm } from "@inertiajs/react";
import { Button, Link } from "@design_system/public";

import { OrderFormFields } from "../../components/orders/form";
import { t } from "../../i18n";

type Props = {
  createPath: string;
  indexPath: string;
  meta: { formToken: string };
  errors: Record<string, string>;
};

export function OrdersNewScreen({ createPath, indexPath, meta, errors }: Props) {
  const form = useForm({ customerName: "", status: "open" });

  return (
    <section className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-display font-semibold">{t("orders.new")}</h1>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          form.transform((data) => ({ ...data, token: meta.formToken }));
          form.post(createPath);
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
          <Button testId="example_orders.orders.new.submit" type="submit" isDisabled={form.processing}>
            {t("orders.save")}
          </Button>
          <Link href={indexPath}>
            <span data-testid="example_orders.orders.new.back">{t("orders.title")}</span>
          </Link>
        </div>
      </form>
    </section>
  );
}
