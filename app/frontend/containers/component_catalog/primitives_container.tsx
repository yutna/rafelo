import { useUiState } from "@core/lib/use_ui_state";

import { ComponentCatalogPrimitives } from "@/components/component_catalog/primitives_section";

export function ComponentCatalogPrimitivesContainer() {
  const [primitives, setPrimitives] = useUiState({
    status: "open",
    owner: "ada",
    tab: "details",
    search: "",
    confirmOpen: false,
  });

  return <ComponentCatalogPrimitives primitives={primitives} onChange={setPrimitives} />;
}
