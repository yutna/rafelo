import type { ColumnDef } from "@tanstack/react-table";

import { rowSortingFeature, tableFeatures } from "@tanstack/react-table";

export const dataTableFeatures = tableFeatures({ rowSortingFeature });

export type DataTableRow = { id: string };

export type DataTableColumn<T extends DataTableRow = DataTableRow> = ColumnDef<
  typeof dataTableFeatures,
  T
>;

export type DataTableSort = { columnId: string; direction: "asc" | "desc" } | null;

export type DataTableProps<T extends DataTableRow> = {
  testId: string;
  data: T[];
  columns: DataTableColumn<T>[];
  emptyLabel: string;
  sort: DataTableSort;
  onSortChange: (sort: DataTableSort) => void;
};
