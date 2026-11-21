import type { ColumnDef } from "@tanstack/react-table";

import { tableFeatures } from "@tanstack/react-table";

export const dataTableFeatures = tableFeatures({});

export type DataTableColumn = ColumnDef<typeof dataTableFeatures, Record<string, unknown>>;
