import { flexRender, useTable } from "@tanstack/react-table";

import type { DataTableColumn } from "./data_table.types";

import { dataTableFeatures } from "./data_table.types";

type DataTableProps = {
  testId: string;
  data: Record<string, unknown>[];
  columns: DataTableColumn[];
  emptyLabel: string;
};

export default function DataTableImpl({ testId, data, columns, emptyLabel }: DataTableProps) {
  const table = useTable({ features: dataTableFeatures, data, columns });

  return (
    <table data-testid={testId} className="w-full text-left text-sm">
      <thead>
        {table.getHeaderGroups().map((group) => (
          <tr key={group.id}>
            {group.headers.map((header) => (
              <th key={header.id} className="border-b px-2 py-2">
                {header.isPlaceholder
                  ? null
                  : flexRender(header.column.columnDef.header, header.getContext())}
              </th>
            ))}
          </tr>
        ))}
      </thead>
      <tbody>
        {table.getRowModel().rows.length === 0 ? (
          <tr>
            <td colSpan={columns.length} className="px-2 py-4">
              {emptyLabel}
            </td>
          </tr>
        ) : (
          table.getRowModel().rows.map((row) => (
            <tr key={row.id}>
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
