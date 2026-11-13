import { useEffect, useRef } from "react";
import type { ReactNode } from "react";

type DialogProps = {
  testId: string;
  title: string;
  open: boolean;
  onClose: () => void;
  closeLabel: string;
  children: ReactNode;
};

export function Dialog({ testId, title, open, onClose, closeLabel, children }: DialogProps) {
  const panel = useRef<HTMLDivElement>(null);
  const close = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return;
    close.current?.focus();
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        onClose();
        return;
      }
      if (event.key !== "Tab" || !panel.current) return;
      const focusable = panel.current.querySelectorAll<HTMLElement>(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])',
      );
      if (focusable.length === 0) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 grid place-items-center bg-slate-900/40 p-4">
      <div
        ref={panel}
        role="dialog"
        aria-modal="true"
        aria-labelledby={`${testId}-title`}
        data-testid={testId}
        className="w-full max-w-lg rounded-card bg-surface p-6 shadow-card"
      >
        <h2 id={`${testId}-title`} className="text-display font-semibold">{title}</h2>
        <div className="mt-4">{children}</div>
        <button ref={close} type="button" onClick={onClose} data-testid={`${testId}.close`} className="mt-6 rounded-card bg-muted px-4 py-2">
          {closeLabel}
        </button>
      </div>
    </div>
  );
}
