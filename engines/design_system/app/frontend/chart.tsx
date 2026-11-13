import { lazy, Suspense } from "react";

import { Skeleton } from "./skeleton";

const ChartImpl = lazy(() => import("./chart_impl"));

type ChartProps = {
  testId: string;
  option: Record<string, unknown>;
  ariaLabel: string;
};

export function Chart(props: ChartProps) {
  return (
    <Suspense fallback={<Skeleton testId={`${props.testId}-loading`} />}>
      <ChartImpl {...props} />
    </Suspense>
  );
}
