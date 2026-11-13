import { createInertiaApp } from "@inertiajs/react";

import { resolvePage } from "../lib/page_resolver";

import "../styles/application.css";

void createInertiaApp({
  resolve: async (name, page) => resolvePage(name, page),
  serverHead: true,
  strictMode: true,
  title: (title) => title || "Rafelo",
});
