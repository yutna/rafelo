import { FieldError, Input, Label, TextField as AriaTextField } from "react-aria-components";

type TextFieldProps = {
  testId: string;
  label: string;
  name?: string;
  type?: string;
  error?: string;
  autoComplete?: string;
  isRequired?: boolean;
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
};

export function TextField({ testId, label, error, ...props }: TextFieldProps) {
  return (
    <AriaTextField {...props} isInvalid={Boolean(error)} className="block text-sm font-medium text-slate-700">
      <Label>{label}</Label>
      <Input data-testid={testId} className="mt-1 w-full rounded-card border border-slate-300 px-3 py-2" />
      <FieldError className="mt-1 block text-danger">{error}</FieldError>
    </AriaTextField>
  );
}
