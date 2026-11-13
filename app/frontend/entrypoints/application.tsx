import { createInertiaApp } from "@inertiajs/react";

import { installGlobalErrorReporting } from "../lib/report_client_error";
import { resolvePage } from "../lib/page_resolver";

import "../styles/application.css";

installGlobalErrorReporting();

void createInertiaApp({
  resolve: async (name, page) => resolvePage(name, page),
  serverHead: true,
  strictMode: true,
  title: (title) => title || "Rafelo",
});
