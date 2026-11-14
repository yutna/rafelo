# Contracts

The envelope every Inertia page receives is generated from
`engines/core/app/frontend/contracts/page_props.schema.ts`. Do not edit the
table by hand: run `npm run docs:generate`, and `npm run docs:check` fails
when it is stale (CT-09).

<!-- generated:envelope:start -->
| Field | Shape | Required |
| --- | --- | --- |
| `auth` | object (viewer: object (id: string, name: string) or null) | yes |
| `trace` | object (requestId: string, traceId: string) | yes |
| `app` | object (name: string, locale: `en` or `th`, locales: array of `en` or `th`, localeHrefs: array of object (locale: `en` or `th`, href: string), timeZone: string) | yes |
| `nav` | array of object (key: string, label: string, path: string, icon: string, current: boolean) | yes |
| `errors` | object of string | yes |
<!-- generated:envelope:end -->

`data`, `meta`, `query`, `pagination`, and `can` are added by `definePage`
(CT-01); the table above is the shared envelope every page receives.
