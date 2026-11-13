import type { ReactNode } from "react";

export function AuthShell({ children }: { children: ReactNode }) {
  return <div className="flex min-h-screen items-center justify-center">{children}</div>;
}
