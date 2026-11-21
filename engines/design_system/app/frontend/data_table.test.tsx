import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import type { DataTableColumn, DataTableSort } from "./data_table.types";

import { DataTable } from "./data_table";

type Row = { id: string; name: string; total: string };

const columns: DataTableColumn<Row>[] = [
  { accessorKey: "name", header: "Name" },
  { accessorKey: "total", header: "Total" },
];

const ada: Row = { id: "ada", name: "Ada", total: "1,200" };
const grace: Row = { id: "grace", name: "Grace", total: "900" };

function renderTable(
  data: Row[] = [ada, grace],
  sort: DataTableSort = null,
  onSortChange = vi.fn(),
) {
  return render(
    <DataTable
      testId="orders-table"
      data={data}
      columns={columns}
      emptyLabel="No orders"
      sort={sort}
      onSortChange={onSortChange}
    />,
  );
}

describe("DataTable", () => {
  it("renders the rows and columns through TanStack Table v9", async () => {
    renderTable();

    const table = await screen.findByTestId("orders-table");
    const headers = within(table).getAllByRole("columnheader");
    const cells = within(table).getAllByRole("cell");

    expect(headers.map((header) => header.textContent)).toEqual(["Name", "Total"]);
    expect(cells.map((cell) => cell.textContent)).toEqual(["Ada", "1,200", "Grace", "900"]);
  });

  it("keeps each row test id with its record after a reorder", async () => {
    const { rerender } = renderTable([ada, grace]);

    expect(await screen.findByTestId("orders-table.row.ada")).toHaveTextContent("Ada");
    expect(screen.getByTestId("orders-table.row.grace")).toHaveTextContent("Grace");

    rerender(
      <DataTable
        testId="orders-table"
        data={[grace, ada]}
        columns={columns}
        emptyLabel="No orders"
        sort={null}
        onSortChange={() => {}}
      />,
    );

    expect(screen.getByTestId("orders-table.row.ada")).toHaveTextContent("Ada");
    expect(screen.getByTestId("orders-table.row.grace")).toHaveTextContent("Grace");
  });

  it("renders the empty state with its own test id", async () => {
    renderTable([]);

    expect(await screen.findByTestId("orders-table.empty")).toHaveTextContent("No orders");
  });

  it("renders aria-sort from the sort prop and reports the next sort", async () => {
    const onSortChange = vi.fn();
    const { rerender } = renderTable(
      [ada, grace],
      { columnId: "name", direction: "asc" },
      onSortChange,
    );

    const headers = within(await screen.findByTestId("orders-table")).getAllByRole("columnheader");
    expect(headers[0]).toHaveAttribute("aria-sort", "ascending");

    await userEvent.click(screen.getByTestId("orders-table.sort.name"));

    expect(onSortChange).toHaveBeenCalledWith({ columnId: "name", direction: "desc" });

    rerender(
      <DataTable
        testId="orders-table"
        data={[ada, grace]}
        columns={columns}
        emptyLabel="No orders"
        sort={{ columnId: "name", direction: "desc" }}
        onSortChange={onSortChange}
      />,
    );

    const sorted = within(screen.getByTestId("orders-table")).getAllByRole("columnheader");
    expect(sorted[0]).toHaveAttribute("aria-sort", "descending");
    expect(sorted[1]).toHaveAttribute("aria-sort", "none");
  });
});
