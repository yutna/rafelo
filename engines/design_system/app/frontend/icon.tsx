import { AlertTriangle, Check, Folder, Receipt } from "lucide-react";

const ICONS = {
  folder: Folder,
  check: Check,
  alert: AlertTriangle,
  receipt: Receipt,
} as const;

export type IconName = keyof typeof ICONS;

export function Icon({ name, size = 16 }: { name: IconName; size?: number }) {
  const Component = ICONS[name];
  return <Component size={size} aria-hidden="true" />;
}
