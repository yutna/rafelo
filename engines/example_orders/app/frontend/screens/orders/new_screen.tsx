import { Button, Link, focusFirstError } from "@design_system/public";
import { OrderFormFields } from "@example_orders/components/orders/form";
import { useOrdersTranslation } from "@example_orders/i18n";
import { useForm } from "@inertiajs/react";
import { useRef } from "react";

type Props = {
  createPath: string;
  indexPath: string;
  meta: { formToken: string };
  errors: Record<string, string>;
};

export function OrdersNewScreen({ createPath, indexPath, meta, errors }: Props) {
  const t = useOrdersTranslation();
  const form = useForm({ customerName: "", status: "open" });
  const formRef = useRef<HTMLFormElement>(null);
  const formErrors: Record<string, string> = { ...errors, ...form.errors };

  return (
    <section className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-display font-semibold">{t("orders.new")}</h1>
      <form
        ref={formRef}
        onSubmit={(event) => {
          event.preventDefault();
          form.transform((data) => ({ ...data, token: meta.formToken }));
          form.post(createPath, {
            onError: () => setTimeout(() => focusFirstError(formRef.current ?? undefined), 0),
          });
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
            testId="example_orders.orders.new.submit"
            type="submit"
            isPending={form.processing}
          >
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
