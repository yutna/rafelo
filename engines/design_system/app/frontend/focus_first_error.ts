const SUMMARY = "[data-error-summary]";
const INVALID = '[aria-invalid="true"]';

export function focusFirstError(scope: ParentNode = document): void {
  const summary = scope.querySelector<HTMLElement>(SUMMARY);
  if (summary) {
    summary.focus();
    return;
  }

  scope.querySelector<HTMLElement>(INVALID)?.focus();
}
