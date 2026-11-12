---
name: expose-public-interface
description: Use when code is shared by two engines, when a consumer needs another engine's class or component, or when deciding whether to extract a domain engine.
---

# Expose a public interface

## Inputs to collect

- The concept and the engine that owns it.
- The consumer engine and the dependency it would declare.
- Whether the code is domain-free, shared by several modules, or specific to one module.

## Choose the home

1. If one engine owns the concept, expose it through that engine's public surface.
2. If no engine clearly owns it, extract a domain engine with `rafelo:domain`.
3. Put it in core only when it is domain-free and every module needs it.

## Build

- Add the public Ruby file under `engines/<engine>/app/public/`.
- Add the public TypeScript re-export under `engines/<engine>/app/frontend/public/`; define the class in `domain/` and re-export it.
- Add the dependency to the consumer's `package.yml`. This is a guard change: name it in the pull request for a person to approve.
- Do not copy code between engines.

## Check

- `bin/packwerk validate`
- `bin/packwerk check`
- `npm run arch:check`
- `script/ci/engine_graph --check`
- `bin/ci`

## Done when

The consumer imports only the public surface, the declared graph is acyclic, the generated graph is current, and `bin/ci` is green.
