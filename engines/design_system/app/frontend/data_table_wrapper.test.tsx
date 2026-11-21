import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

vi.mock("./data_table_impl", () => ({
  default: () => <div data-testid="table.impl" />,
}));

import type { DataTableColumn } from "./data_table.types";

import { DataTable } from "./data_table";

type Row = { id: string; name: string };

const columns: DataTableColumn<Row>[] = [{ accessorKey: "name", header: "Name" }];

describe("DataTable wrapper", () => {
  it("shows its loading state until the lazy implementation arrives", async () => {
    render(
      <DataTable
        testId="lazy.table"
        data={[{ id: "one", name: "One" }]}
        columns={columns}
        emptyLabel="No rows"
        sort={null}
        onSortChange={() => {}}
      />,
    );

    expect(screen.getByTestId("lazy.table.loading")).toBeInTheDocument();
    expect(await screen.findByTestId("table.impl")).toBeInTheDocument();
    expect(screen.queryByTestId("lazy.table.loading")).not.toBeInTheDocument();
  });
});
