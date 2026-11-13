import type { InputHTMLAttributes } from "react";

type TextFieldProps = InputHTMLAttributes<HTMLInputElement> & {
  testId: string;
  label: string;
  error?: string;
};

export function TextField({ testId, label, error, id, ...props }: TextFieldProps) {
  const inputId = id ?? testId;
  return (
    <label className="block text-sm font-medium text-slate-700" htmlFor={inputId}>
      {label}
      <input
        id={inputId}
        data-testid={testId}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? `${inputId}-error` : undefined}
        className="mt-1 w-full rounded-card border border-slate-300 px-3 py-2"
        {...props}
      />
      {error ? (
        <span id={`${inputId}-error`} role="alert" className="mt-1 block text-danger">
          {error}
        </span>
      ) : null}
    </label>
  );
}
