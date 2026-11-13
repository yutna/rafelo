// Public design-system exports. This file is scanned by the cross-engine clone detector.
export const DESIGN_SYSTEM_NAME = "design_system";
export const DESIGN_SYSTEM_GEM = "rafelo_design_system";

export function designSystemName(): string {
  return DESIGN_SYSTEM_NAME;
}

export function designSystemGem(): string {
  return DESIGN_SYSTEM_GEM;
}

export { Image } from "../image";
export { Link } from "../link";
export { Deferred } from "../deferred";
export { isSafeUrl, isAppPath } from "../safe_url";

export { calendarFor, formatDate, formatNumber, isValidIsoDate } from "../formatters";
export { DateField } from "../date_field";
export { I18nProvider, useLocale } from "../i18n_provider";
