import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { DataTableColumn } from "./data_table.types";

import { DataTable } from "./data_table";

const columns: DataTableColumn[] = [
  { accessorKey: "name", header: "Name" },
  { accessorKey: "total", header: "Total" },
];

describe("DataTable", () => {
  it("renders the rows and columns through TanStack Table v9", async () => {
    render(
      <DataTable
        testId="orders-table"
        data={[
          { name: "Ada", total: "1,200" },
          { name: "Grace", total: "900" },
        ]}
        columns={columns}
        emptyLabel="No orders"
      />,
    );

    const table = await screen.findByTestId("orders-table");
    const headers = within(table).getAllByRole("columnheader");
    const cells = within(table).getAllByRole("cell");

    expect(headers.map((header) => header.textContent)).toEqual(["Name", "Total"]);
    expect(cells.map((cell) => cell.textContent)).toEqual(["Ada", "1,200", "Grace", "900"]);
  });

  it("renders the empty label when there are no rows", async () => {
    render(<DataTable testId="orders-table" data={[]} columns={columns} emptyLabel="No orders" />);

    const table = await screen.findByTestId("orders-table");

    expect(within(table).getByRole("cell")).toHaveTextContent("No orders");
  });
});
