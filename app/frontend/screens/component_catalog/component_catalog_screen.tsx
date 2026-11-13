import { Button } from "@design_system/button";
import { Chart } from "@design_system/chart";
import { DataTable } from "@design_system/data_table";
import { Dialog } from "@design_system/dialog";
import { Icon } from "@design_system/icon";
import { Pagination } from "@design_system/pagination";
import { Skeleton } from "@design_system/skeleton";
import { TextField } from "@design_system/text_field";
import { Toast } from "@design_system/toast";
import { useUiState } from "@core/lib/use_ui_state";

const columns = [
  { accessorKey: "name", header: "Name" },
  { accessorKey: "total", header: "Total" },
];

export function ComponentCatalogScreen() {
  const [menu, setMenu] = useUiState({ open: false });
  const [pagination, setPagination] = useUiState({ page: 1 });

  return (
    <div className="mx-auto max-w-3xl space-y-8 px-6 py-16">
      <h1 className="text-display font-semibold">Component catalog</h1>
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Controls</h2>
        <Button testId="catalog-button" onClick={() => setMenu({ open: true })}>Open dialog</Button>
        <TextField testId="catalog-field" label="Name" error="Required" />
        <Toast testId="catalog-toast" tone="success">Saved</Toast>
        <Skeleton testId="catalog-skeleton" />
        <Pagination testId="catalog-pagination" page={pagination.page} perPage={10} total={30} onPageChange={(page) => setPagination({ page })} />
        <Icon name="folder" />
      </section>
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Data</h2>
        <DataTable testId="catalog-table" data={[{ name: "Ada", total: "1,200" }]} columns={columns} emptyLabel="No rows" />
        <Chart testId="catalog-chart" ariaLabel="Sample chart" option={{ xAxis: { type: "category", data: ["A", "B"] }, yAxis: { type: "value" }, series: [{ type: "bar", data: [1, 2] }] }} />
      </section>
      <Dialog testId="catalog-dialog" title="Dialog" open={menu.open} onClose={() => setMenu({ open: false })}>
        Dialog body
      </Dialog>
    </div>
  );
}
