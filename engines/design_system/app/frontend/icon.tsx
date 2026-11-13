import { AlertTriangle, Check, Folder } from "lucide-react";

const ICONS = {
  folder: Folder,
  check: Check,
  alert: AlertTriangle,
} as const;

export type IconName = keyof typeof ICONS;

export function Icon({ name, size = 16 }: { name: IconName; size?: number }) {
  const Component = ICONS[name];
  return <Component size={size} aria-hidden="true" />;
}
