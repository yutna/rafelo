import type { ReactNode } from "react";

type EmptyStateProps = {
  testId: string;
  title: string;
  description?: string;
  action?: ReactNode;
};

export function EmptyState({ testId, title, description, action }: EmptyStateProps) {
  return (
    <section
      data-testid={testId}
      className="rounded-card border border-dashed border-slate-300 bg-surface p-6 text-center"
    >
      <h2 className="text-lg font-semibold">{title}</h2>
      {description ? <p className="mt-2 text-sm text-slate-600">{description}</p> : null}
      {action ? <div className="mt-4">{action}</div> : null}
    </section>
  );
}
