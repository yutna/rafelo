import { createInertiaApp } from "@inertiajs/react";

import "../styles/application.css";

void createInertiaApp({
  pages: "../pages",
  serverHead: true,
  strictMode: true,
  title: (title) => title || "Rafelo",
});
