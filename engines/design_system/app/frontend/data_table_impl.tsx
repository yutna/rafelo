import type { SortingState } from "@tanstack/react-table";

import { flexRender, useTable } from "@tanstack/react-table";

import type { DataTableProps, DataTableSort } from "./data_table.types";

import { dataTableFeatures } from "./data_table.types";

function sortingState(sort: DataTableSort): SortingState {
  return sort ? [{ id: sort.columnId, desc: sort.direction === "desc" }] : [];
}

function nextSort(sorting: SortingState): DataTableSort {
  const [first] = sorting;
  if (!first) return null;
  return { columnId: first.id, direction: first.desc ? "desc" : "asc" };
}

function ariaSort(direction: false | "asc" | "desc"): "ascending" | "descending" | "none" {
  if (direction === "asc") return "ascending";
  if (direction === "desc") return "descending";
  return "none";
}

export default function DataTableImpl<T extends { id: string }>({
  testId,
  data,
  columns,
  emptyLabel,
  sort,
  onSortChange,
}: DataTableProps<T>) {
  const sorting = sortingState(sort);
  const table = useTable({
    features: dataTableFeatures,
    data,
    columns,
    enableSortingRemoval: false,
    getRowId: (row) => row.id,
    manualSorting: true,
    onSortingChange: (updater) => {
      onSortChange(nextSort(typeof updater === "function" ? updater(sorting) : updater));
    },
    state: { sorting },
  });

  return (
    <table data-testid={testId} className="w-full text-left text-sm">
      <thead>
        {table.getHeaderGroups().map((group) => (
          <tr key={group.id}>
            {group.headers.map((header) => {
              const direction = header.column.getIsSorted();
              const sortable = header.column.getCanSort();

              return (
                <th
                  key={header.id}
                  aria-sort={sortable ? ariaSort(direction) : undefined}
                  className="border-b px-2 py-2"
                >
                  {header.isPlaceholder ? null : sortable ? (
                    <button
                      type="button"
                      data-testid={`${testId}.sort.${header.column.id}`}
                      onClick={header.column.getToggleSortingHandler()}
                      className="inline-flex items-center gap-1 rounded-card outline-offset-2 hover:underline focus-visible:outline-2"
                    >
                      {flexRender(header.column.columnDef.header, header.getContext())}
                      <span aria-hidden="true">
                        {direction === "asc" ? "▲" : direction === "desc" ? "▼" : ""}
                      </span>
                    </button>
                  ) : (
                    flexRender(header.column.columnDef.header, header.getContext())
                  )}
                </th>
              );
            })}
          </tr>
        ))}
      </thead>
      <tbody>
        {table.getRowModel().rows.length === 0 ? (
          <tr>
            <td colSpan={columns.length} data-testid={`${testId}.empty`} className="px-2 py-4">
              {emptyLabel}
            </td>
          </tr>
        ) : (
          table.getRowModel().rows.map((row) => (
            <tr key={row.id} data-testid={`${testId}.row.${row.id}`}>
              {row.getAllCells().map((cell) => (
                <td key={cell.id} className="border-b px-2 py-2">
                  {flexRender(cell.column.columnDef.cell, cell.getContext())}
                </td>
              ))}
            </tr>
          ))
        )}
      </tbody>
    </table>
  );
}
