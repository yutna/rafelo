const engineRules = require("./.dependency-cruiser.engines.generated.json");

const FRONTEND = "(^|/)app/frontend/";

module.exports = {
  forbidden: [
    ...engineRules,
    {
      name: "kernel-internals-stay-inside",
      severity: "error",
      from: { pathNot: "^engines/(core|design_system)/" },
      to: { path: "^engines/(core|design_system)/app/frontend/internal/" },
    },
    {
      name: "no-circular",
      severity: "error",
      from: {},
      to: { circular: true },
    },
    {
      name: "nothing-depends-on-example-engines",
      severity: "error",
      from: { path: "^(app|engines|e2e|script)/", pathNot: "^engines/example_" },
      to: { path: "^engines/example_" },
    },
    {
      name: "domain-is-framework-free",
      severity: "error",
      from: { path: `${FRONTEND}(domain|forms)/` },
      to: {
        path: [
          "node_modules/(react|react-dom|@inertiajs|i18next|react-i18next|tailwind-variants|tailwind-merge|react-aria-components|echarts|lucide-react)/",
          "^engines/design_system/",
          `${FRONTEND}(components|containers|screens|pages|hooks|layouts)/`,
        ],
      },
    },
    {
      name: "pages-render-screens",
      severity: "error",
      from: { path: `${FRONTEND}pages/` },
      to: { path: `${FRONTEND}(containers|components|hooks|domain|forms)/` },
    },
    {
      name: "only-resolver-picks-layouts",
      severity: "error",
      from: { path: `${FRONTEND}(pages|screens|containers|components)/` },
      to: { path: "^app/frontend/layouts/" },
    },
    {
      name: "components-stay-presentational",
      severity: "error",
      from: { path: `${FRONTEND}components/` },
      to: { path: `${FRONTEND}(containers|hooks|screens|pages)/` },
    },
  ],
  options: {
    tsConfig: { fileName: "tsconfig.base.json" },
    tsPreCompilationDeps: true,
    doNotFollow: { path: "node_modules" },
    exclude: { path: "spec/enforcement/fixtures" },
  },
};
