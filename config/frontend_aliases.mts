import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url)).replace(/\/$/, "");

export const engineAliases = [
  { find: "@core", replacement: `${root}/engines/core/app/frontend` },
  { find: "@design_system", replacement: `${root}/engines/design_system/app/frontend` },
  { find: "@example_customers", replacement: `${root}/engines/example_customers/app/frontend` },
  { find: "@engines", replacement: `${root}/engines` },
  { find: "@", replacement: `${root}/app/frontend` },
];

export const engineFsAllow = [
  `${root}`,
  `${root}/engines`,
  `${root}/app/frontend`
];
