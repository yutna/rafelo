import type { ReactNode } from "react";

export function BareShell({ children }: { children: ReactNode }) {
  return (
    <main id="main-content" tabIndex={-1} className="min-h-screen">
      {children}
    </main>
  );
}
