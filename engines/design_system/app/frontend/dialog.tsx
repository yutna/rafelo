import { Dialog as AriaDialog, Modal, ModalOverlay } from "react-aria-components";
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
  return (
    <ModalOverlay
      isOpen={open}
      onOpenChange={(isOpen) => { if (!isOpen) onClose(); }}
      isDismissable
      className="fixed inset-0 grid place-items-center bg-slate-900/40 p-4"
    >
      <Modal className="w-full max-w-lg rounded-card bg-surface p-6 shadow-card">
        <AriaDialog data-testid={testId} aria-label={title} className="outline-none">
          <h2 className="text-display font-semibold">{title}</h2>
          <div className="mt-4">{children}</div>
          <button type="button" onClick={onClose} data-testid={`${testId}.close`} className="mt-6 rounded-card bg-muted px-4 py-2">
            {closeLabel}
          </button>
        </AriaDialog>
      </Modal>
    </ModalOverlay>
  );
}
