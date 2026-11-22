import type { DataTableColumn, DataTableSort } from "@design_system/data_table.types";

import { useUiState } from "@core/lib/use_ui_state";
import { Button } from "@design_system/button";
import { Chart } from "@design_system/chart";
import { DataTable } from "@design_system/data_table";
import { Dialog } from "@design_system/dialog";
import { Icon } from "@design_system/icon";
import { Pagination } from "@design_system/pagination";
import { Skeleton } from "@design_system/skeleton";
import { TextField } from "@design_system/text_field";
import { Toast } from "@design_system/toast";
import { lazy, Suspense } from "react";

import { t } from "@/lib/i18n";

type CatalogRow = { id: string; name: string; total: string };

const ComponentCatalogPrimitives = lazy(() =>
  import("@/containers/component_catalog/primitives_container").then((module) => ({
    default: module.ComponentCatalogPrimitivesContainer,
  })),
);

export function ComponentCatalogContainer() {
  const [menu, setMenu] = useUiState({ open: false });
  const [pagination, setPagination] = useUiState({ page: 1 });
  const [sort, setSort] = useUiState<{ sort: DataTableSort }>({ sort: null });
  const columns: DataTableColumn<CatalogRow>[] = [
    { accessorKey: "name", header: t("app:catalog.name") },
    { accessorKey: "total", header: t("app:catalog.total") },
  ];

  return (
    <div className="mx-auto max-w-3xl space-y-8 px-6 py-16">
      <h1 className="text-display font-semibold">{t("app:catalog.title")}</h1>
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">{t("app:catalog.controls")}</h2>
        <Button testId="catalog-button" onPress={() => setMenu({ open: true })}>
          {t("app:catalog.open_dialog")}
        </Button>
        <TextField
          testId="catalog-field"
          label={t("app:catalog.name")}
          error={t("app:catalog.required")}
        />
        <Toast testId="catalog-toast" tone="success">
          {t("app:catalog.saved")}
        </Toast>
        <Skeleton testId="catalog-skeleton" />
        <Pagination
          testId="catalog-pagination"
          page={pagination.page}
          perPage={10}
          total={30}
          label={t("app:catalog.pagination")}
          previousLabel={t("app:catalog.previous")}
          nextLabel={t("app:catalog.next")}
          onPageChange={(page) => setPagination({ page })}
        />
        <Icon name="folder" />
      </section>
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">{t("app:catalog.data")}</h2>
        <DataTable
          testId="catalog-table"
          data={[{ id: "ada", name: "Ada", total: "1,200" }]}
          columns={columns}
          emptyLabel={t("app:catalog.empty")}
          sort={sort.sort}
          onSortChange={(next) => setSort({ sort: next })}
        />
        <Chart
          testId="catalog-chart"
          ariaLabel={t("app:catalog.sample")}
          description={t("app:catalog.sample")}
          series={[
            {
              name: t("app:catalog.sample"),
              type: "pie",
              data: [
                { label: "A", value: 1 },
                { label: "B", value: 2 },
              ],
            },
          ]}
        />
      </section>
      <Suspense fallback={<Skeleton testId="catalog-primitives.loading" />}>
        <ComponentCatalogPrimitives />
      </Suspense>
      <Dialog
        testId="catalog-dialog"
        title={t("app:catalog.dialog")}
        open={menu.open}
        onClose={() => setMenu({ open: false })}
        closeLabel={t("app:catalog.close")}
      >
        {t("app:catalog.dialog_body")}
      </Dialog>
    </div>
  );
}
