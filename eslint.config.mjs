// The 09 ESLint configuration (A1). Path-scoped rules keep each layer's
// exemptions exact; the canaries in script/ci/eslint_canary prove them at real
// paths.
import js from "@eslint/js";
import comments from "@eslint-community/eslint-plugin-eslint-comments";
import betterTailwindcss from "eslint-plugin-better-tailwindcss";
import jsxA11y from "eslint-plugin-jsx-a11y";
import perfectionist from "eslint-plugin-perfectionist";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import unicorn from "eslint-plugin-unicorn";
import globals from "globals";
import tseslint from "typescript-eslint";
import prettier from "eslint-config-prettier";

import rafelo from "./script/ci/eslint/rafelo.mjs";

const DESIGN_SYSTEM = "engines/design_system/app/frontend";
const ICON_MAP = `${DESIGN_SYSTEM}/icon.tsx`;
const FORMATTERS = `${DESIGN_SYSTEM}/formatters.ts`;
const ERROR_BOUNDARY = `${DESIGN_SYSTEM}/error_boundary.tsx`;
const PAGE_RESOLVER = "app/frontend/lib/page_resolver.tsx";
const LAYOUTS = "app/frontend/layouts/**";
const DOMAIN_CODE = ["**/app/frontend/domain/**", "**/app/frontend/forms/**"];
const TESTS = ["e2e/**/*.ts", "engines/*/e2e/**/*.ts", "**/*.test.{ts,tsx}"];
const DOMAIN_TESTS = ["**/app/frontend/domain/**/*.test.ts", "**/app/frontend/forms/**/*.test.ts"];
const STATE_WRAPPERS = [
  "engines/core/app/frontend/lib/use_domain_reducer.ts",
  "engines/core/app/frontend/lib/use_ui_state.ts",
];
const STATE_HOOKS = ["useState", "useReducer", "useActionState", "useOptimistic"];
const STATE_HOOKS_MESSAGE = "Use useDomainReducer or useUiState from @core/lib (FE-04).";
const URL_MESSAGE = "Do not build URLs in TypeScript; use the href Rails sends in props (ARCH-10).";
const USE_PAGE_MESSAGE =
  "Pages parse their props and pass them down; only layouts and the page resolver call usePage (CT-04).";
const SELECTOR_MESSAGE = "Select by role with an accessible name, or by test id (TS-04).";
const TYPE_EXPORT_MESSAGE = "A .tsx file exports no types; move them to a *.types.ts file (FE-05).";
const CLASS_COMPONENT_MESSAGE =
  "React code is functional; the design_system error boundary is the one class component (OOP-01).";
const DS_INERTIA_MESSAGE =
  "design_system takes only Link and Deferred from Inertia; visits, page props, and forms belong to the engines (FE-03).";
const TEXT_QUERY =
  "/^((get|query|find)(All)?By(Text|LabelText|PlaceholderText|DisplayValue|Title|AltText)|getBy(Label|Placeholder)|locator|querySelector(All)?)$/";
const ROLE_QUERY = "/^(get|query|find)(All)?ByRole$/";

const IMPORTS = {
  base: {
    patterns: [
      { group: ["../*"], message: "Use an alias or ./ (FE-05)." },
      {
        group: [
          "react-router*",
          "@tanstack/react-query",
          "redux",
          "zustand",
          "styled-components",
          "@emotion/*",
        ],
        message:
          "Inertia is the router and the data layer; style through the design system (FE-03, FE-12).",
      },
    ],
  },
  stateHooks: {
    paths: [{ name: "react", importNames: STATE_HOOKS, message: STATE_HOOKS_MESSAGE }],
  },
  usePage: {
    paths: [{ name: "@inertiajs/react", importNames: ["usePage"], message: USE_PAGE_MESSAGE }],
  },
  engines: {
    patterns: [
      {
        group: ["@engines/*"],
        message:
          "Only the page resolver uses @engines/; use @core/, @design_system/, or @<engine>/public/ (ARCH-10).",
      },
    ],
  },
  designSystemLibraries: {
    patterns: [
      {
        group: [
          "react-aria-components",
          "@internationalized/date",
          "tailwind-variants",
          "tailwind-merge",
          "echarts",
          "echarts/*",
          "@tanstack/react-table",
        ],
        message: "Use the @design_system/ component, wrapper, or formatter (FE-07, FE-08, FE-20).",
      },
    ],
  },
  icons: {
    patterns: [{ group: ["lucide-react"], message: "Use @design_system/icon (FE-17)." }],
  },
  designSystemInertia: {
    paths: [
      {
        name: "@inertiajs/react",
        allowImportNames: ["Link", "Deferred"],
        message: DS_INERTIA_MESSAGE,
      },
    ],
    patterns: [{ group: ["@inertiajs/*", "!@inertiajs/react"], message: DS_INERTIA_MESSAGE }],
  },
};

const PROPERTIES = {
  stateHooks: STATE_HOOKS.map((property) => ({
    object: "React",
    property,
    message: STATE_HOOKS_MESSAGE,
  })),
};

const SYNTAX = {
  formatting: [
    {
      selector:
        "MemberExpression[object.name='Intl'][property.name=/^(DateTimeFormat|NumberFormat|RelativeTimeFormat)$/]",
      message: "Format dates, numbers, and money with @design_system/formatters (FE-11, FE-20).",
    },
    {
      selector: "CallExpression[callee.property.name=/^toLocale(Date|Time)?String$/]",
      message: "Format with @design_system/formatters (FE-11, FE-20).",
    },
    {
      selector: "CallExpression[callee.property.name='toFixed']",
      message: "Format numbers and money with @design_system/formatters (FE-11).",
    },
  ],
  dateGetters: [
    {
      selector:
        "CallExpression[callee.property.name=/^(getFullYear|getUTCFullYear|getMonth|getDate)$/]",
      message:
        "Show calendar dates through @design_system/formatters; a Thai year is a Buddhist Era year (FE-20).",
    },
  ],
  glob: [
    {
      selector: "MemberExpression[object.type='MetaProperty'][property.name='glob']",
      message: "Only the page resolver uses import.meta.glob (ARCH-10).",
    },
  ],
  urlBuilding: [
    { selector: "TemplateLiteral[quasis.0.value.raw=/^\\x2F(\\w|$)/]", message: URL_MESSAGE },
    {
      selector: "BinaryExpression[operator='+'][left.type='Literal'][left.value=/^\\x2F(\\w|$)/]",
      message: URL_MESSAGE,
    },
  ],
  typeExports: [
    {
      selector:
        ":matches(ExportNamedDeclaration, ExportAllDeclaration, ExportSpecifier)[exportKind='type']",
      message: TYPE_EXPORT_MESSAGE,
    },
    { selector: "ExportDefaultDeclaration > TSInterfaceDeclaration", message: TYPE_EXPORT_MESSAGE },
  ],
  classComponents: [
    {
      selector: ":matches(ClassDeclaration, ClassExpression)[superClass.name=/^(Pure)?Component$/]",
      message: CLASS_COMPONENT_MESSAGE,
    },
    {
      selector:
        ":matches(ClassDeclaration, ClassExpression)[superClass.property.name=/^(Pure)?Component$/]",
      message: CLASS_COMPONENT_MESSAGE,
    },
  ],
  selectors: [
    { selector: `CallExpression[callee.property.name=${TEXT_QUERY}]`, message: SELECTOR_MESSAGE },
    { selector: `CallExpression[callee.name=${TEXT_QUERY}]`, message: SELECTOR_MESSAGE },
    {
      selector: `CallExpression[callee.property.name=${ROLE_QUERY}] Property[key.name='name'] > Literal`,
      message: "Take the accessible name from the i18n helper, not a literal (TS-04).",
    },
    {
      selector: `CallExpression[callee.name=${ROLE_QUERY}] Property[key.name='name'] > Literal`,
      message: "Take the accessible name from the i18n helper, not a literal (TS-04).",
    },
  ],
};

const restrictImports = (...keys) => [
  "error",
  {
    paths: keys.flatMap((key) => IMPORTS[key].paths ?? []),
    patterns: keys.flatMap((key) => IMPORTS[key].patterns ?? []),
  },
];
const restrictProperties = (...keys) => ["error", ...keys.flatMap((key) => PROPERTIES[key])];
const restrictSyntax = (...keys) => ["error", ...keys.flatMap((key) => SYNTAX[key])];

export default [
  {
    ignores: [
      "spec/enforcement/fixtures/**",
      "node_modules/**",
      "public/**",
      "tmp/**",
      "vendor/**",
      "engines/design_system/api.d.ts",
      "coverage/**",
      "test-results/**",
      "playwright-report/**",
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["**/*.{ts,tsx}"],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
      globals: { ...globals.browser, ...globals.node },
    },
    plugins: {
      react,
      "react-hooks": reactHooks,
      "jsx-a11y": jsxA11y,
      unicorn,
      perfectionist,
      "@eslint-community/eslint-comments": comments,
      "better-tailwindcss": betterTailwindcss,
    },
    settings: {
      react: { version: "detect" },
      "better-tailwindcss": { entryPoint: "app/frontend/styles/application.css" },
    },
    rules: {
      ...react.configs.recommended.rules,
      "react/react-in-jsx-scope": "off",
      "react/prop-types": "off",
      ...reactHooks.configs.recommended.rules,
      ...jsxA11y.configs.recommended.rules,
      "unicorn/filename-case": ["error", { case: "snakeCase" }],
      "perfectionist/sort-imports": "error",
      "@typescript-eslint/prefer-readonly": "error",
      "better-tailwindcss/no-unknown-classes": "error",
      "@eslint-community/eslint-comments/require-description": "error",
      "react/no-danger": "error",
      "no-restricted-imports": restrictImports(
        "base",
        "stateHooks",
        "usePage",
        "engines",
        "designSystemLibraries",
        "icons",
      ),
      "no-restricted-properties": restrictProperties("stateHooks"),
      "no-restricted-syntax": restrictSyntax(
        "formatting",
        "dateGetters",
        "glob",
        "urlBuilding",
        "classComponents",
      ),
    },
  },
  {
    files: ["**/*.tsx"],
    rules: {
      "no-restricted-syntax": restrictSyntax(
        "formatting",
        "dateGetters",
        "glob",
        "urlBuilding",
        "typeExports",
        "classComponents",
      ),
    },
  },
  {
    files: [`${DESIGN_SYSTEM}/**`],
    ignores: [ICON_MAP],
    rules: {
      "no-restricted-imports": restrictImports("base", "engines", "icons", "designSystemInertia"),
      "no-restricted-properties": "off",
    },
  },
  {
    files: [ICON_MAP],
    rules: {
      "no-restricted-imports": restrictImports("base", "engines", "designSystemInertia"),
      "no-restricted-properties": "off",
    },
  },
  {
    files: STATE_WRAPPERS,
    rules: {
      "no-restricted-imports": restrictImports(
        "base",
        "usePage",
        "engines",
        "designSystemLibraries",
        "icons",
      ),
      "no-restricted-properties": "off",
    },
  },
  {
    files: [LAYOUTS],
    rules: {
      "no-restricted-imports": restrictImports(
        "base",
        "stateHooks",
        "engines",
        "designSystemLibraries",
        "icons",
      ),
    },
  },
  {
    files: [PAGE_RESOLVER],
    rules: {
      "no-restricted-imports": restrictImports(
        "base",
        "stateHooks",
        "designSystemLibraries",
        "icons",
      ),
      "no-restricted-syntax": restrictSyntax(
        "formatting",
        "dateGetters",
        "typeExports",
        "classComponents",
      ),
    },
  },
  {
    files: DOMAIN_CODE,
    rules: {
      "no-restricted-syntax": restrictSyntax(
        "formatting",
        "glob",
        "urlBuilding",
        "classComponents",
      ),
    },
  },
  {
    files: [FORMATTERS],
    rules: { "no-restricted-syntax": restrictSyntax("glob", "classComponents") },
  },
  {
    files: [ERROR_BOUNDARY],
    rules: {
      "no-restricted-syntax": restrictSyntax(
        "formatting",
        "dateGetters",
        "glob",
        "urlBuilding",
        "typeExports",
      ),
    },
  },
  {
    files: ["**/*.tsx"],
    ignores: [`${DESIGN_SYSTEM}/**`],
    rules: {
      "react/forbid-elements": [
        "error",
        {
          forbid: [
            { element: "button", message: "Use Button from @design_system/ (FE-07)." },
            { element: "input", message: "Use a design_system field (FE-07)." },
            { element: "select", message: "Use a design_system select (FE-07)." },
            { element: "textarea", message: "Use a design_system text area (FE-07)." },
          ],
        },
      ],
    },
  },
  {
    files: TESTS,
    plugins: { rafelo },
    rules: {
      "no-restricted-syntax": restrictSyntax(
        "formatting",
        "dateGetters",
        "glob",
        "classComponents",
        "selectors",
      ),
      "rafelo/skip-needs-issue": "error",
    },
  },
  {
    files: ["**/*.test.tsx"],
    rules: {
      "no-restricted-syntax": restrictSyntax(
        "formatting",
        "dateGetters",
        "glob",
        "typeExports",
        "classComponents",
        "selectors",
      ),
    },
  },
  {
    files: DOMAIN_TESTS,
    rules: {
      "no-restricted-syntax": restrictSyntax("formatting", "glob", "classComponents", "selectors"),
    },
  },
  {
    // The URL validators and the i18n placeholder scanner deliberately match
    // control characters (FE-18, CT-08).
    files: [
      "engines/design_system/app/frontend/safe_url.ts",
      "engines/core/app/frontend/contracts/app_path.schema.ts",
      "script/contracts/i18n.mts",
    ],
    rules: { "no-control-regex": "off" },
  },
  {
    files: ["**/*.mjs"],
    languageOptions: { globals: { ...globals.node } },
  },
  {
    files: ["**/*.cjs"],
    languageOptions: { sourceType: "commonjs", globals: { ...globals.node } },
    rules: { "@typescript-eslint/no-require-imports": "off" },
  },
  prettier,
];
