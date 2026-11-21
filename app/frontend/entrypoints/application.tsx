import { createInertiaApp } from "@inertiajs/react";
import { createRoot } from "react-dom/client";

import { resolvePage } from "@/lib/page_resolver";
import { installGlobalErrorReporting } from "@/lib/report_client_error";
import { RootBoundary } from "@/lib/root_boundary";
import "@/styles/application.css";

installGlobalErrorReporting();

void createInertiaApp({
  resolve: async (name, page) => resolvePage(name, page),
  setup({ el, App, props }) {
    if (!el) return;

    createRoot(el).render(
      <RootBoundary pageUrl={props.initialPage.url} trace={props.initialPage.props.trace}>
        <App {...props} />
      </RootBoundary>,
    );
  },
  serverHead: true,
  strictMode: true,
  // The progress bar injects a <style>; the request nonce lets it pass the
  // CSP instead of reporting a violation (SEC-05).
  nonce: document.querySelector<HTMLMetaElement>('meta[name="csp-nonce"]')?.content,
  title: (title) => title || "Rafelo",
});
