import type { ReactNode } from "react";

export function BareShell({ children }: { children: ReactNode }) {
  return <div className="min-h-screen">{children}</div>;
}
