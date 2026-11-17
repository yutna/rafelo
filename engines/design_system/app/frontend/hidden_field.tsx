type HiddenFieldProps = {
  testId: string;
  name: string;
  value: string;
};

export function HiddenField({ testId, name, value }: HiddenFieldProps) {
  return <input type="hidden" name={name} value={value} data-testid={testId} />;
}
