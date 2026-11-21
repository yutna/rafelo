import type { DataTableColumn, DataTableSort } from "@design_system/data_table.types";

import { useUiState } from "@core/lib/use_ui_state";
import { Button } from "@design_system/button";
import { Chart } from "@design_system/chart";
import { ComboBox } from "@design_system/combobox";
import { ConfirmDialog } from "@design_system/confirm_dialog";
import { DataTable } from "@design_system/data_table";
import { Dialog } from "@design_system/dialog";
import { EmptyState } from "@design_system/empty_state";
import { FilterBar } from "@design_system/filter_bar";
import { Icon } from "@design_system/icon";
import { Menu } from "@design_system/menu";
import { Pagination } from "@design_system/pagination";
import { Select } from "@design_system/select";
import { Skeleton } from "@design_system/skeleton";
import { Tabs } from "@design_system/tabs";
import { TextField } from "@design_system/text_field";
import { Toast } from "@design_system/toast";

import { t } from "@/lib/i18n";

type CatalogRow = { id: string; name: string; total: string };

export function ComponentCatalogScreen() {
  const [menu, setMenu] = useUiState({ open: false });
  const [pagination, setPagination] = useUiState({ page: 1 });
  const [sort, setSort] = useUiState<{ sort: DataTableSort }>({ sort: null });
  const [primitives, setPrimitives] = useUiState({
    status: "open",
    owner: "ada",
    tab: "details",
    search: "",
    confirmOpen: false,
  });
  const columns: DataTableColumn<CatalogRow>[] = [
    { accessorKey: "name", header: t("app:catalog.name") },
    { accessorKey: "total", header: t("app:catalog.total") },
  ];
  const statusItems = [
    { id: "open", label: t("app:catalog.open") },
    { id: "paid", label: t("app:catalog.paid") },
  ];
  const people = [
    { id: "ada", label: "Ada" },
    { id: "grace", label: "Grace" },
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
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">{t("app:catalog.primitives")}</h2>
        <div className="grid gap-4 sm:grid-cols-2">
          <Select
            testId="catalog-select"
            label={t("app:catalog.status")}
            items={statusItems}
            selectedKey={primitives.status}
            onSelectionChange={(key) => setPrimitives({ status: key })}
          />
          <ComboBox
            testId="catalog-combobox"
            label={t("app:catalog.owner")}
            items={people}
            selectedKey={primitives.owner}
            onSelectionChange={(key) => setPrimitives({ owner: key })}
          />
          <Menu
            testId="catalog-menu"
            label={t("app:catalog.actions")}
            items={[
              { id: "archive", label: t("app:catalog.archive") },
              { id: "delete", label: t("app:catalog.delete") },
            ]}
            onAction={(id) => {
              if (id === "delete") setPrimitives({ confirmOpen: true });
            }}
          />
          <div>
            <Tabs
              testId="catalog-tabs"
              label={t("app:catalog.sections")}
              tabs={[
                {
                  id: "details",
                  label: t("app:catalog.details"),
                  content: t("app:catalog.details_body"),
                },
                {
                  id: "history",
                  label: t("app:catalog.history"),
                  content: t("app:catalog.history_body"),
                },
              ]}
              selectedKey={primitives.tab}
              onSelectionChange={(key) => setPrimitives({ tab: key })}
            />
          </div>
        </div>
        <FilterBar
          testId="catalog-filters"
          label={t("app:catalog.filters")}
          searchLabel={t("app:catalog.search")}
          searchValue={primitives.search}
          onSearchChange={(value) => setPrimitives({ search: value })}
        >
          <Select
            testId="catalog-filter-status"
            label={t("app:catalog.status")}
            items={statusItems}
            selectedKey={primitives.status}
            onSelectionChange={(key) => setPrimitives({ status: key })}
          />
        </FilterBar>
        <Button
          testId="catalog-confirm-open"
          variant="danger"
          onPress={() => setPrimitives({ confirmOpen: true })}
        >
          {t("app:catalog.delete")}
        </Button>
        <EmptyState
          testId="catalog-empty"
          title={t("app:catalog.empty_title")}
          description={t("app:catalog.empty_description")}
          action={<Button testId="catalog-empty-action">{t("app:catalog.create")}</Button>}
        />
        <ConfirmDialog
          testId="catalog-confirm"
          title={t("app:catalog.confirm_title")}
          message={t("app:catalog.confirm_message")}
          confirmLabel={t("app:catalog.delete")}
          cancelLabel={t("app:catalog.cancel")}
          open={primitives.confirmOpen}
          onConfirm={() => setPrimitives({ confirmOpen: false })}
          onCancel={() => setPrimitives({ confirmOpen: false })}
          destructive
        />
      </section>
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
