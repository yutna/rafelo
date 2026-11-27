# frozen_string_literal: true

# The ESLint canary paths and cases in one table. script/ci/eslint_canary runs
# them; script/ci/enforcement_canaries reads their `rules` to require a case for
# every discovered local rule, so a comment naming a rule cannot satisfy the
# meta-check (TS-07).
module Rafelo
  module ESLintCanary
    module_function

    def existing_path(root, *paths)
      paths.find { |path| File.exist?(File.join(root, path)) } ||
        abort("eslint_canary: none of #{paths.join(', ')} exists; checked 0")
    end

    def paths(root)
      {
        engine_page: existing_path(root, "engines/example_orders/app/frontend/pages/orders/index.tsx",
                                    "app/frontend/pages/home/index.tsx"),
        engine_test: existing_path(root, "app/frontend/components/page_heading.test.tsx"),
        engine_e2e: existing_path(root, "engines/example_orders/e2e/orders.spec.ts",
                                  "engines/design_system/e2e/catalog.spec.ts"),
        design_system: existing_path(root, "engines/design_system/app/frontend/button.tsx"),
        design_system_test: existing_path(root, "engines/design_system/app/frontend/date_field.test.tsx"),
        error_boundary: existing_path(root, "engines/design_system/app/frontend/error_boundary.tsx"),
        formatters: existing_path(root, "engines/design_system/app/frontend/formatters.ts"),
        page_resolver: existing_path(root, "app/frontend/lib/page_resolver.tsx"),
        layout: existing_path(root, "app/frontend/layouts/layout_root.tsx"),
        unit_test: existing_path(root, "app/frontend/components/page_heading.test.tsx"),
        core_domain: existing_path(root, "engines/core/app/frontend/domain/money.ts"),
        core_domain_test: existing_path(root, "engines/core/app/frontend/domain/money.test.ts"),
        dummy_schema: existing_path(root,
                                   "engines/core/spec/dummy_engine/app/frontend/pages/dummy/widgets.schema.ts"),
        use_ui_state: existing_path(root, "engines/core/app/frontend/lib/use_ui_state.ts"),
        icon_map: existing_path(root, "engines/design_system/app/frontend/icon.tsx"),
        home_page: existing_path(root, "app/frontend/pages/home/index.tsx")
      }
    end

    def cases(root)
      path = paths(root)
      [
        { name: "imports", fixture: "imports/bad.tsx", path: path[:engine_page],
          rules: [ "no-restricted-imports" ] },
        { name: "state hooks", fixture: "state/bad.tsx", path: path[:engine_page],
          rules: [ "no-restricted-imports", "no-restricted-properties" ] },
        { name: "usePage", fixture: "use_page/bad.tsx", path: path[:engine_page],
          rules: [ "no-restricted-imports" ] },
        { name: "design_system Inertia imports", fixture: "design_system_inertia/bad.tsx",
          path: path[:design_system], rules: [ "no-restricted-imports" ] },
        { name: "formatting APIs", fixture: "formatting/bad.tsx", path: path[:engine_page],
          rules: [ "no-restricted-syntax" ] },
        { name: "date getters", fixture: "dates/bad.tsx", path: path[:engine_page],
          rules: [ "no-restricted-syntax" ] },
        { name: "import.meta.glob", fixture: "glob/bad.tsx", path: path[:engine_page],
          rules: [ "no-restricted-syntax" ] },
        { name: "URL building", fixture: "urls/bad.tsx", path: path[:engine_page],
          rules: [ "no-restricted-syntax" ] },
        { name: "type exports", fixture: "type_exports/bad.tsx", path: path[:engine_page],
          rules: [ "no-restricted-syntax" ] },
        { name: "readonly fields", fixture: "prefer_readonly/bad.ts", path: path[:core_domain],
          rules: [ "@typescript-eslint/prefer-readonly" ] },
        { name: "class components", fixture: "class_components/bad.tsx", path: path[:engine_page],
          rules: [ "no-restricted-syntax" ] },
        { name: "test selectors", fixture: "selectors/bad.tsx", path: path[:unit_test],
          rules: [ "no-restricted-syntax" ] },
        { name: "raw elements", fixture: "elements/bad.tsx", path: path[:engine_page],
          rules: [ "react/forbid-elements" ] },
        { name: "dangerous HTML", fixture: "danger/bad.tsx", path: path[:engine_page],
          rules: [ "react/no-danger" ] },
        { name: "filename case", fixture: "filename/bad.tsx",
          path: "engines/core/spec/dummy_engine/app/frontend/pages/dummy/PageHeadingBad.ts",
          rules: [ "unicorn/filename-case" ], write: true },
        { name: "import order", fixture: "sort_imports/bad.tsx", path: path[:engine_page],
          rules: [ "perfectionist/sort-imports" ] },
        { name: "disable description", fixture: "directives/bad.tsx", path: path[:engine_page],
          rules: [ "@eslint-community/eslint-comments/require-description" ] },
        { name: "Tailwind classes", fixture: "tailwind/bad.tsx", path: path[:engine_page],
          rules: [ "better-tailwindcss/no-unknown-classes" ] },
        { name: "skipped tests", fixture: "skip/bad.tsx", path: path[:engine_test],
          rules: [ "rafelo/skip-needs-issue" ], count: 16 },
        { name: "dummy engine schema", fixture: "urls/bad.tsx", path: path[:dummy_schema],
          rules: [ "no-restricted-syntax" ] }
      ]
    end

    def legal_cases(root)
      path = paths(root)
      [
        { name: "engine imports", fixture: "imports/legal.tsx", path: path[:engine_page] },
        { name: "design_system state", fixture: "state/legal.tsx", path: path[:design_system_test] },
        { name: "layout usePage", fixture: "use_page/legal.tsx", path: path[:layout] },
        { name: "design_system Inertia allow-list", fixture: "design_system_inertia/legal.tsx",
          path: path[:design_system] },
        { name: "formatters", fixture: "formatting/legal.ts", path: path[:formatters] },
        { name: "domain date getters", fixture: "dates/legal.ts", path: path[:core_domain] },
        { name: "page resolver glob", fixture: "glob/legal.ts", path: path[:page_resolver] },
        { name: "test URLs", fixture: "urls/legal.ts", path: path[:engine_e2e] },
        { name: "error boundary class", fixture: "class_components/legal.tsx",
          path: path[:error_boundary] },
        { name: "readonly fields legal", fixture: "prefer_readonly/legal.ts", path: path[:core_domain] },
        { name: "role and test id selectors", fixture: "selectors/legal.tsx", path: path[:unit_test] },
        { name: "design_system raw elements", fixture: "elements/legal.tsx",
          path: path[:design_system] },
        { name: "safe HTML", fixture: "danger/legal.tsx", path: path[:engine_page] },
        { name: "filename case legal", fixture: "filename/legal.tsx", path: path[:engine_page] },
        { name: "import order legal", fixture: "sort_imports/legal.tsx", path: path[:engine_page] },
        { name: "disable description legal", fixture: "directives/legal.tsx",
          path: path[:engine_page] },
        { name: "known Tailwind classes", fixture: "tailwind/legal.tsx", path: path[:engine_page] },
        { name: "skips with issues", fixture: "skip/legal.tsx", path: path[:engine_test] }
      ]
    end

    def print_config(root)
      path = paths(root)
      [
        {
          path: path[:engine_page],
          imports: { names: [ "react", "@inertiajs/react" ],
                     groups: [ "../*", "react-router*", "@engines/*", "lucide-react",
                               "react-aria-components" ] },
          import_names: { "react" => %w[useState useReducer useActionState useOptimistic] },
          properties: :on,
          syntax: { include: [ "Intl", "toFixed", "getFullYear", "property.name='glob'",
                               "TemplateLiteral", "BinaryExpression", "ExportDefaultDeclaration",
                               "superClass.name", "superClass.property.name" ] },
          forbid_elements: :on
        },
        {
          path: path[:design_system],
          imports: { names: [ "@inertiajs/react" ], absent_names: [ "react" ],
                     groups: [ "@engines/*", "lucide-react" ],
                     absent_groups: [ "react-aria-components" ] },
          properties: :off,
          syntax: { include: [ "Intl", "TemplateLiteral", "ExportDefaultDeclaration",
                               "superClass.name" ] },
          forbid_elements: :off
        },
        {
          path: path[:use_ui_state],
          imports: { names: [ "@inertiajs/react" ], absent_names: [ "react" ] },
          properties: :off
        },
        {
          path: path[:layout],
          imports: { names: [ "react" ], absent_names: [ "@inertiajs/react" ] }
        },
        {
          path: path[:page_resolver],
          imports: { names: [ "react" ], absent_names: [ "@inertiajs/react" ],
                     absent_groups: [ "@engines/*" ] },
          syntax: { include: [ "ExportDefaultDeclaration", "getFullYear" ],
                    exclude: [ "TemplateLiteral", "property.name='glob'" ] }
        },
        {
          path: path[:core_domain],
          syntax: { include: [ "Intl", "TemplateLiteral", "property.name='glob'" ],
                    exclude: [ "getFullYear" ] },
          prefer_readonly: :on
        },
        {
          path: path[:formatters],
          syntax: { include: [ "property.name='glob'" ],
                    exclude: [ "Intl", "toFixed", "TemplateLiteral", "getFullYear" ] }
        },
        {
          path: path[:error_boundary],
          syntax: { include: [ "Intl", "ExportDefaultDeclaration" ], exclude: [ "superClass.name" ] }
        },
        {
          path: path[:icon_map],
          imports: { names: [ "@inertiajs/react" ], absent_groups: [ "lucide-react" ] }
        },
        {
          path: path[:unit_test],
          imports: { names: [ "react" ] },
          syntax: { include: [ "ByRole", "Property[key.name='name']", "ExportDefaultDeclaration" ],
                    exclude: [ "TemplateLiteral" ] },
          skip_rule: :on
        },
        {
          path: path[:engine_e2e],
          syntax: { include: [ "ByRole" ], exclude: [ "TemplateLiteral" ] },
          skip_rule: :on
        },
        {
          path: path[:core_domain_test],
          syntax: { include: [ "ByRole" ], exclude: [ "getFullYear" ] },
          skip_rule: :on
        },
        {
          path: path[:design_system_test],
          imports: { absent_names: [ "react" ] },
          properties: :off,
          syntax: { include: [ "ByRole" ] },
          skip_rule: :on
        },
        {
          path: path[:home_page],
          imports: { names: [ "react", "@inertiajs/react" ], groups: [ "@engines/*" ] },
          syntax: { include: [ "TemplateLiteral", "ExportDefaultDeclaration" ] },
          forbid_elements: :on
        },
        {
          path: path[:dummy_schema],
          imports: { names: [ "react" ], groups: [ "../*" ] },
          properties: :on,
          syntax: { include: [ "Intl", "TemplateLiteral", "property.name='glob'" ] },
          prefer_readonly: :on
        }
      ]
    end
  end
end
