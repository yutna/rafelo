import type { ReactNode } from "react";

import { Deferred as InertiaDeferred } from "@inertiajs/react";

export function Deferred({
  data,
  children,
  fallback,
}: {
  data: string;
  children: ReactNode;
  fallback: ReactNode;
}) {
  return (
    <InertiaDeferred data={data} fallback={fallback}>
      {children}
    </InertiaDeferred>
  );
}
