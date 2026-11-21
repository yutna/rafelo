const SUMMARY = "[data-error-summary]";
const INVALID = '[aria-invalid="true"]';

export function focusFirstError(scope: ParentNode = document): void {
  const invalid = scope.querySelector<HTMLElement>(INVALID);
  if (invalid) {
    invalid.focus();
    return;
  }

  scope.querySelector<HTMLElement>(SUMMARY)?.focus();
}
