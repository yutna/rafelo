import type { ReactElement } from "react";

import { lazy, Suspense } from "react";

import type { DataTableProps, DataTableRow } from "./data_table.types";

import { Skeleton } from "./skeleton";

type DataTableComponent = <T extends DataTableRow>(props: DataTableProps<T>) => ReactElement;

const DataTableImpl = lazy(() => import("./data_table_impl")) as unknown as DataTableComponent;

export function DataTable<T extends DataTableRow>(props: DataTableProps<T>) {
  return (
    <Suspense fallback={<Skeleton testId={`${props.testId}.loading`} />}>
      <DataTableImpl {...props} />
    </Suspense>
  );
}
