import { createElement, type ComponentType, type ReactNode } from "react";

import { AppShell } from "@/layouts/app_shell";
import { AuthShell } from "@/layouts/auth_shell";
import { BareShell } from "@/layouts/bare_shell";
import { LayoutRoot } from "@/layouts/layout_root";
import { PageBoundary } from "@/layouts/page_boundary";

import type { LayoutName } from "./layout_name";

import { setLocale } from "./i18n";
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
const compiled = new Map<string, PageComponent>();

function pageName(path: string): string {
  return (
    path
      .replace(/\.tsx$/, "")
      .split("/pages/")
      .at(-1) ?? ""
  );
}

for (const [path, load] of Object.entries(appPageModules)) {
  pages.set(pageName(path), load);
}

for (const [path, load] of Object.entries(enginePageModules)) {
  if (path.includes("/spec/")) continue;
  const engine = path.split("/engines/")[1]?.split("/")[0];
  const resource = pageName(path);
  if (!engine || !resource) continue;
  pages.set(`${engine}/${resource}`, load);
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
  await setLocale(app?.locale ?? "en");
  const load = pages.get(name);
  if (!load) throw new Error(`Page not found: ${name}`);

  const module = await load();
  return withLayout(module.default, name);
}
