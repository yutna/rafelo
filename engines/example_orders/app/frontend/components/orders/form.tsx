import { TextField } from "@design_system/public";

type Props = {
  customerName: string;
  status: string;
  errors: Record<string, string>;
  onCustomerNameChange: (value: string) => void;
  onStatusChange: (value: string) => void;
};

export function OrderFormFields({
  customerName,
  status,
  errors,
  onCustomerNameChange,
  onStatusChange,
}: Props) {
  return (
    <>
      <TextField
        testId="example_orders.orders.form.customer"
        label="Customer"
        name="customerName"
        value={customerName}
        onChange={onCustomerNameChange}
        error={errors.customerName}
        isRequired
      />
      <TextField
        testId="example_orders.orders.form.status"
        label="Status"
        name="status"
        value={status}
        onChange={onStatusChange}
        error={errors.status}
        isRequired
      />
    </>
  );
}
