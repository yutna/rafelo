import { lazy, Suspense } from "react";

import type { DataTableColumn } from "./data_table.types";

import { Skeleton } from "./skeleton";

const DataTableImpl = lazy(() => import("./data_table_impl"));

type DataTableProps = {
  testId: string;
  data: Record<string, unknown>[];
  columns: DataTableColumn[];
  emptyLabel: string;
};

export function DataTable(props: DataTableProps) {
  return (
    <Suspense fallback={<Skeleton testId={`${props.testId}-loading`} />}>
      <DataTableImpl {...props} />
    </Suspense>
  );
}
