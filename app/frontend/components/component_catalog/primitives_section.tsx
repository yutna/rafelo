import { Button } from "@design_system/button";
import { ComboBox } from "@design_system/combobox";
import { ConfirmDialog } from "@design_system/confirm_dialog";
import { EmptyState } from "@design_system/empty_state";
import { FilterBar } from "@design_system/filter_bar";
import { Menu } from "@design_system/menu";
import { Select } from "@design_system/select";
import { Tabs } from "@design_system/tabs";

import { t } from "@/lib/i18n";

type Primitives = {
  status: string;
  owner: string;
  tab: string;
  search: string;
  confirmOpen: boolean;
};

export function ComponentCatalogPrimitives({
  primitives,
  onChange,
}: {
  primitives: Primitives;
  onChange: (patch: Partial<Primitives>) => void;
}) {
  const statusItems = [
    { id: "open", label: t("app:catalog.open") },
    { id: "paid", label: t("app:catalog.paid") },
  ];
  const people = [
    { id: "ada", label: "Ada" },
    { id: "grace", label: "Grace" },
  ];

  return (
    <section className="space-y-4">
      <h2 className="text-xl font-semibold">{t("app:catalog.primitives")}</h2>
      <div className="grid gap-4 sm:grid-cols-2">
        <Select
          testId="catalog-select"
          label={t("app:catalog.status")}
          items={statusItems}
          selectedKey={primitives.status}
          onSelectionChange={(key) => onChange({ status: key })}
        />
        <ComboBox
          testId="catalog-combobox"
          label={t("app:catalog.owner")}
          items={people}
          selectedKey={primitives.owner}
          onSelectionChange={(key) => onChange({ owner: key })}
        />
        <Menu
          testId="catalog-menu"
          label={t("app:catalog.actions")}
          items={[
            { id: "archive", label: t("app:catalog.archive") },
            { id: "delete", label: t("app:catalog.delete") },
          ]}
          onAction={(id) => {
            if (id === "delete") onChange({ confirmOpen: true });
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
            onSelectionChange={(key) => onChange({ tab: key })}
          />
        </div>
      </div>
      <FilterBar
        testId="catalog-filters"
        label={t("app:catalog.filters")}
        searchLabel={t("app:catalog.search")}
        searchValue={primitives.search}
        onSearchChange={(value) => onChange({ search: value })}
      >
        <Select
          testId="catalog-filter-status"
          label={t("app:catalog.status")}
          items={statusItems}
          selectedKey={primitives.status}
          onSelectionChange={(key) => onChange({ status: key })}
        />
      </FilterBar>
      <Button
        testId="catalog-confirm-open"
        variant="danger"
        onPress={() => onChange({ confirmOpen: true })}
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
        onConfirm={() => onChange({ confirmOpen: false })}
        onCancel={() => onChange({ confirmOpen: false })}
        destructive
      />
    </section>
  );
}
