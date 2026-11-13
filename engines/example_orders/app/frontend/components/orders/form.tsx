import { TextField } from "@design_system/public";

import { useOrdersTranslation } from "../../i18n";

type Props = {
  customerName: string;
  status: string;
  baseError?: string;
  errors: Record<string, string>;
  onCustomerNameChange: (value: string) => void;
  onStatusChange: (value: string) => void;
};

export function OrderFormFields({
  customerName,
  status,
  baseError,
  errors,
  onCustomerNameChange,
  onStatusChange,
}: Props) {
  const t = useOrdersTranslation();
  return (
    <>
      {baseError ? (
        <p role="alert" data-testid="example_orders.orders.form.base-error" className="text-danger">
          {baseError}
        </p>
      ) : null}
      <TextField
        testId="example_orders.orders.form.customer"
        label={t("orders.customer")}
        name="customerName"
        value={customerName}
        onChange={onCustomerNameChange}
        error={errors.customerName}
        isRequired
      />
      <TextField
        testId="example_orders.orders.form.status"
        label={t("orders.status")}
        name="status"
        value={status}
        onChange={onStatusChange}
        error={errors.status}
        isRequired
      />
    </>
  );
}
