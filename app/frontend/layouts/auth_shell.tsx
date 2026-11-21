import type { ReactNode } from "react";

export function AuthShell({ children }: { children: ReactNode }) {
  return (
    <main id="main-content" tabIndex={-1} className="flex min-h-screen items-center justify-center">
      {children}
    </main>
  );
}
