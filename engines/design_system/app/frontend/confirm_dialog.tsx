import { Button } from "./button";
import { Dialog } from "./dialog";

type ConfirmDialogProps = {
  testId: string;
  title: string;
  message: string;
  confirmLabel: string;
  cancelLabel: string;
  open: boolean;
  onConfirm: () => void;
  onCancel: () => void;
  destructive?: boolean;
};

export function ConfirmDialog({
  testId,
  title,
  message,
  confirmLabel,
  cancelLabel,
  open,
  onConfirm,
  onCancel,
  destructive = false,
}: ConfirmDialogProps) {
  return (
    <Dialog
      testId={testId}
      title={title}
      open={open}
      onClose={onCancel}
      closeLabel={cancelLabel}
      showClose={false}
    >
      <p>{message}</p>
      <div className="mt-6 flex justify-end gap-2">
        <Button testId={`${testId}.cancel`} variant="secondary" onPress={onCancel}>
          {cancelLabel}
        </Button>
        <Button
          testId={`${testId}.confirm`}
          variant={destructive ? "danger" : "primary"}
          onPress={onConfirm}
        >
          {confirmLabel}
        </Button>
      </div>
    </Dialog>
  );
}
