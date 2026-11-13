import type { ReactNode } from "react";

export function Toast({ testId, tone = "info", children }: { testId: string; tone?: "info" | "success" | "danger"; children: ReactNode }) {
  const role = tone === "danger" ? "alert" : "status";
  return (
    <div role={role} data-testid={testId} className="rounded-card bg-surface px-4 py-3 shadow-card">
      {children}
    </div>
  );
}
