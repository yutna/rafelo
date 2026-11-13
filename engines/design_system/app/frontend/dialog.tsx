import type { ReactNode } from "react";

type DialogProps = {
  testId: string;
  title: string;
  open: boolean;
  onClose: () => void;
  children: ReactNode;
};

export function Dialog({ testId, title, open, onClose, children }: DialogProps) {
  if (!open) return null;
  return (
    <div role="dialog" aria-modal="true" aria-labelledby={`${testId}-title`} data-testid={testId} className="fixed inset-0 grid place-items-center bg-slate-900/40 p-4">
      <div className="w-full max-w-lg rounded-card bg-surface p-6 shadow-card">
        <h2 id={`${testId}-title`} className="text-display font-semibold">{title}</h2>
        <div className="mt-4">{children}</div>
        <button type="button" onClick={onClose} data-testid={`${testId}-close`} className="mt-6 rounded-card bg-muted px-4 py-2">
          Close
        </button>
      </div>
    </div>
  );
}
