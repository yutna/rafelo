import { AlertTriangle, Check, Folder, Receipt } from "lucide-react";

import type { IconName } from "./icon.types";

const ICONS = {
  folder: Folder,
  check: Check,
  alert: AlertTriangle,
  receipt: Receipt,
} as const satisfies Record<IconName, unknown>;

export function Icon({ name, size = 16 }: { name: IconName; size?: number }) {
  const Component = ICONS[name];
  return <Component size={size} aria-hidden="true" />;
}
