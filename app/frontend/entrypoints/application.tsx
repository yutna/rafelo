import { createInertiaApp } from "@inertiajs/react";
import type { ComponentType } from "react";

import { setLocale } from "../lib/i18n";

import "../styles/application.css";

void createInertiaApp({
  resolve: async (name, page) => {
    const locale = (page?.props?.app as { locale?: string } | undefined)?.locale ?? "en";
    await setLocale(locale);
    const pages = import.meta.glob<{ default: unknown }>("../pages/**/*.tsx");
    const loader = pages[`../pages/${name}.tsx`];
    if (!loader) throw new Error(`Page not found: ${name}`);
    const module = await loader();
    return (module.default ?? module) as ComponentType<Record<string, unknown>>;
  },
  serverHead: true,
  strictMode: true,
  title: (title) => title || "Rafelo",
});
