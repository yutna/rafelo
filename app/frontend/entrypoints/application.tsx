import { createInertiaApp } from "@inertiajs/react";

import "../styles/application.css";
import "../lib/i18n";

void createInertiaApp({
  pages: "../pages",
  serverHead: true,
  strictMode: true,
  title: (title) => title || "Rafelo",
});
