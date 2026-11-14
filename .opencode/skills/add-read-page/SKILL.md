---
name: add-read-page
description: Use when adding a read-only index or show page to an existing product module, or when a new resource needs its first read slice.
---

# Add a read page

## Inputs to collect

- The product module, the resource, and whether it needs `index`, `show`, or both.
- The upstream endpoint, the fields the viewer may see, and the sort/filter keys.
- The permissions that gate the page and the empty/error copy for each locale.

## Generate

For a new resource:

```sh
bin/rails generate rafelo:page <module> <resource> --actions=index,show
```

For an existing resource, add the action by hand: route, controller action,
policy method, props object, page/screen/container/component, contract, copy,
permission key, request spec, and upstream fixture.

## Fill in

- `engines/<module>/config/routes.rb` and the controller action.
- `engines/<module>/app/policies/<app>/<module>/<resource>_policy.rb`; the
  `can` keys are the page's declared capabilities.
- `engines/<module>/app/gateways/<app>/<module>/<resources>_gateway.rb`; the
  gateway is the only place that calls the upstream.
- `engines/<module>/app/props/<app>/<module>/<resources>_{index,show}_props.rb`
  and the frontend props type.
- `engines/<module>/app/frontend/pages|screens|containers|components/<resources>/`
  and `engines/<module>/config/contracts/pages/<resources>/`.
- `engines/<module>/config/locales/*.yml`,
  `engines/<module>/config/permissions.yml`, and
  `engines/<module>/spec/fixtures/upstream/<upstream>/` (the generator names
  the folder after the resource; rename it when the module's upstream key
  differs).
- `spec/requests/<module>/<resources>_spec.rb`; keep the schema, SQL, upstream
  call budget, props budget, resolvable hrefs, and policy capability checks.

## Rules that apply

GEN-02; BE-01; BE-03; BE-04; BE-06; BE-16; BE-17; CT-01; CT-08; CT-10; FE-01;
FE-09; FE-11; TS-01; TS-02; TS-04; ARCH-09; ARCH-10; OOP-05.

## Check

- `bin/check <module>`
- `bin/ci`

## Design skills

Load `oo-design` before shaping the props and gateway objects, `oo-ruby` for
the Ruby value/props objects, `oo-typescript` for `domain/` and `forms/`
classes, and `oo-working-within-a-framework` for the controller and React
components. Load `oo-reviewing-object-design` when reviewing the diff. A rule
or ADR wins over the pack.

## Done when

The page renders through one screen, the gateway is the only upstream caller,
the permissions and copy exist in every configured locale, the request spec
proves the contract and budgets, and `bin/ci` is green.
