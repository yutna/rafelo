import { createElement, type ComponentType, type ReactNode } from "react";

import { AppShell } from "@/layouts/app_shell";
import { AuthShell } from "@/layouts/auth_shell";
import { BareShell } from "@/layouts/bare_shell";
import { LayoutRoot } from "@/layouts/layout_root";
import { PageBoundary } from "@/layouts/page_boundary";

import type { LayoutName } from "./layout_name";

import { loadNamespaces, type CatalogLoader } from "./i18n";
import { setPageContext } from "./report_client_error";

type PageModule = { default: PageComponent };
type PageComponent = ComponentType<Record<string, unknown>> & {
  layoutName?: LayoutName;
  layout?: (page: ReactNode) => ReactNode;
};

const appPageModules = import.meta.glob<PageModule>(
  ["../pages/**/*.tsx", "!../pages/**/*.test.tsx", "!../pages/**/*.spec.tsx"],
  { eager: false },
);
const enginePageModules = import.meta.glob<PageModule>(
  [
    "../../../engines/*/app/frontend/pages/**/*.tsx",
    "!../../../engines/*/app/frontend/pages/**/*.test.tsx",
    "!../../../engines/*/app/frontend/pages/**/*.spec.tsx",
  ],
  { eager: false },
);
const appCatalogModules = import.meta.glob<CatalogModule>("../locales/*.json", {
  eager: false,
});
const engineCatalogModules = import.meta.glob<CatalogModule>(
  "../../../engines/*/app/frontend/locales/*.json",
  { eager: false },
);

const LAYOUTS: Record<LayoutName, (page: ReactNode) => ReactNode> = {
  app: (page) => (
    <LayoutRoot>
      <AppShell>{page}</AppShell>
    </LayoutRoot>
  ),
  auth: (page) => (
    <LayoutRoot>
      <AuthShell>{page}</AuthShell>
    </LayoutRoot>
  ),
  bare: (page) => (
    <LayoutRoot>
      <BareShell>{page}</BareShell>
    </LayoutRoot>
  ),
};

const pages = new Map<string, () => Promise<PageModule>>();
const pageNamespaces = new Map<string, string>();
const catalogs = new Map<string, CatalogLoader>();
const compiled = new Map<string, PageComponent>();

type CatalogModule = { default: Record<string, unknown> };

function pageName(path: string): string {
  return (
    path
      .replace(/\.tsx$/, "")
      .split("/pages/")
      .at(-1) ?? ""
  );
}

function localeName(path: string): string {
  return (
    path
      .split("/")
      .at(-1)
      ?.replace(/\.json$/, "") ?? ""
  );
}

for (const [path, load] of Object.entries(appPageModules)) {
  pages.set(pageName(path), load);
  pageNamespaces.set(pageName(path), "app");
}

for (const [path, load] of Object.entries(enginePageModules)) {
  if (path.includes("/spec/")) continue;
  const engine = path.split("/engines/")[1]?.split("/")[0];
  const resource = pageName(path);
  if (!engine || !resource) continue;
  pages.set(`${engine}/${resource}`, load);
  pageNamespaces.set(`${engine}/${resource}`, engine);
}

for (const [path, load] of Object.entries(appCatalogModules)) {
  catalogs.set(`app:${localeName(path)}`, load);
}

for (const [path, load] of Object.entries(engineCatalogModules)) {
  const engine = path.split("/engines/")[1]?.split("/")[0];
  if (!engine) continue;
  catalogs.set(`${engine}:${localeName(path)}`, load);
}

function withLayout(component: PageComponent, name: string): PageComponent {
  const cached = compiled.get(name);
  if (cached) return cached;

  const layoutName = component.layoutName ?? "app";
  const Wrapper: PageComponent = (props) => (
    <PageBoundary trace={props.trace}>{createElement(component, props)}</PageBoundary>
  );
  Wrapper.layout = LAYOUTS[layoutName] ?? LAYOUTS.app;
  compiled.set(name, Wrapper);
  return Wrapper;
}

export async function resolvePage(
  name: string,
  page?: { props?: Record<string, unknown>; version?: string | null },
): Promise<PageComponent> {
  const app = page?.props?.app as { locale?: string } | undefined;
  setPageContext({
    page: name,
    release: page?.version ?? undefined,
    trace: page?.props?.trace as { requestId?: string; traceId?: string } | undefined,
  });
  const load = pages.get(name);
  if (!load) throw new Error(`Page not found: ${name}`);

  const namespace = pageNamespaces.get(name) ?? "app";
  const namespaces = ["app", "core", "design_system"];
  if (!namespaces.includes(namespace)) namespaces.push(namespace);
  await loadNamespaces(namespaces, app?.locale ?? "en", catalogs);

  const module = await load();
  return withLayout(module.default, name);
}
