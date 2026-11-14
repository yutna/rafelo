---
name: add-write-action
description: Use when adding a new, edit, create, or update action that changes data through a form, or when a page needs a write slice.
---

# Add a write action

## Inputs to collect

- The product module, the resource, and the write actions (`new,edit` implies
  `create,update`).
- The upstream endpoint, the fields the viewer may submit, and which of them
  the viewer may see again.
- The validation rules, the 303/error/notice behavior, and every locale's copy.

## Generate

For a new resource:

```sh
bin/rails generate rafelo:page <module> <resource> --actions=new,edit
```

For an existing resource, add the write slice by hand: route, controller
actions, policy methods, form object, props objects, contract, copy, permission
keys, request spec, and upstream fixture.

## Fill in

- The form object under
  `engines/<module>/app/forms/<app>/<module>/<resource>_form.rb`; input from a
  person is checked by `issues()`, not exceptions.
- The controller `new`, `create`, `edit`, and `update` actions; a successful
  write redirects with 303, a validation failure re-renders with issues.
- The idempotency claim and form token; do not use a cache for idempotency.
- The policy methods and permission keys for `create` and `update`.
- The `new`/`edit` props, frontend pages/screens/containers/components, and the
  form schema in `engines/<module>/config/contracts/pages/<resources>/`.
- Copy in every configured locale and the request spec for success,
  validation failure, permission refusal, and replay.
- The upstream fixture under
  `engines/<module>/spec/fixtures/upstream/<upstream>/` (the generator names
  the folder after the resource; rename it when the module's upstream key
  differs); the gateway remains the only upstream caller.

## Rules that apply

GEN-02; BE-01; BE-03; BE-06; BE-13; BE-15; BE-16; BE-17; BE-20; CT-01; CT-08;
CT-10; OOP-03; OOP-04; OOP-05; TS-02; TS-04; FE-07; FE-09; SEC-02.

## Check

- `bin/check <module>`
- `bin/ci`

## Design skills

Load `oo-design` before shaping the form and props objects, `oo-ruby` for the
form/value objects, `oo-typescript` for the framework-free form classes, and
`oo-working-within-a-framework` for the controller and React form. Load
`oo-reviewing-object-design` when reviewing the diff. A rule or ADR wins over
the pack.

## Done when

The write is authorized, validated by `issues()`, idempotent, redirects with
303 or re-renders with issues, has copy in every configured locale, and
`bin/ci` is green.
