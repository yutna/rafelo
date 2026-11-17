import { createInertiaApp } from "@inertiajs/react";

import { installGlobalErrorReporting } from "../lib/report_client_error";
import { resolvePage } from "../lib/page_resolver";

import "../styles/application.css";

installGlobalErrorReporting();

void createInertiaApp({
  resolve: async (name, page) => resolvePage(name, page),
  serverHead: true,
  strictMode: true,
  // The progress bar injects a <style> without the request nonce, which the
  // CSP reports; the shell keeps its own loading states (SEC-05).
  progress: false,
  title: (title) => title || "Rafelo",
});
