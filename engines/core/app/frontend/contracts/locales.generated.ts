// Generated from config/locales.yml; do not edit.
import { z } from "zod";

export const localeSchema = z.enum(["en","th"] as const);
export type Locale = z.infer<typeof localeSchema>;
export const defaultLocale: Locale = "en";
