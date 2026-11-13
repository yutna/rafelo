import type { ReactNode } from "react";

type LayoutRootProps = {
  children: ReactNode;
};

export function LayoutRoot({ children }: LayoutRootProps) {
  return <div className="min-h-screen bg-slate-50 text-slate-900">{children}</div>;
}
