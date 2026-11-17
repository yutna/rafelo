import { createInertiaApp } from "@inertiajs/react";

import { installGlobalErrorReporting } from "../lib/report_client_error";
import { resolvePage } from "../lib/page_resolver";

import "../styles/application.css";

installGlobalErrorReporting();

void createInertiaApp({
  resolve: async (name, page) => resolvePage(name, page),
  serverHead: true,
  strictMode: true,
  // The progress bar injects a <style>; the request nonce lets it pass the
  // CSP instead of reporting a violation (SEC-05).
  nonce: document.querySelector<HTMLMetaElement>('meta[name="csp-nonce"]')?.content,
  title: (title) => title || "Rafelo",
});
