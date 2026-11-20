# Spec provenance

`docs/architecture/` (the 16 specification files listed below) in this repository **is** the
specification. The external copy it was imported from has been deleted; nothing syncs from
anywhere any more, and no file points to an outside copy.

- Imported: 2026-11-12 (from the external copy)
- Repository as the specification source since: 2026-11-20
- Files: 16
- Lines: 9602

A spec change enters from the owner: an owner comment that gives exact wording for named files
and sections is the approval for that wording; it is applied in a pull request that links the
issue (see `docs/development/implementation-protocol.md`, section 1). A reading you need still
goes into a `spec:` question first (section 10).

`docs/architecture/AGENTS.md` is the historical copy of the guide, not the guide any agent
loads. OpenCode loads the repository root `AGENTS.md`; the shipped and corrected guide is that
file. The historical copy is preserved verbatim, including its old "Put secrets or real personal
data in code" sentence. That sentence is not an instruction: the root guide says "Put no
secrets or real personal data in code, tests, fixtures, logs, or issues" (BE-08).

## File inventory

| File                     | Lines | SHA-256  |
| ------------------------ | ----: | -------- |
| `00_README.md`           |   434 | `cf9f021c429d0917c96e5b2399809dd07136554eba5d3fb4c51989f3a76db91f` |
| `01_architecture.md`     |   675 | `40eb45ba64ab16d3af25eb572f15da25370feb6bd1d07e1078251cb80ab9a4f4` |
| `02_backend.md`          |  1295 | `d483745f0049581dbb4385347b9ec8e7803d2d9de920ee8ffc2f48f7d537c3c8` |
| `03_session_security.md` |   596 | `0685a391df29ca4b54bd923bad5d08f1a971c37c7d02b44088ba431eb84c5cab` |
| `04_contracts.md`        |   676 | `8da88d681dd412c42513dc81618639fcf87bedffb6374ffcf26465bd79024459` |
| `05_frontend.md`         |  1082 | `53e889b074cc9c71fd409a11618462143430d64049ef16deb7ed74ba939b565a` |
| `06_frontend_oop.md`     |   378 | `ecab39b8392521a029c4da215258357ef3fd41d39c87b9ef18604a001de3b926` |
| `07_testing.md`          |   573 | `28df877fa4ed98674ef1461e007750ca9ccaa6a315f3e05345658cac0a6be498` |
| `08_generators.md`       |   429 | `6c9560e44edc44f28468a5b2485c6af9131570f919c7019a7915e9699e61395e` |
| `09_enforcement.md`      |  1233 | `c823b012419c5823cd6f9c0a0208e3a068cd54f7d85cfb0bb59f62bda52b8649` |
| `10_decisions.md`        |   564 | `ecc2d662ea84046d3ab5bce858af49fdd406851a6a49377fbff5f590c4f3cae2` |
| `11_workflow.md`         |   482 | `85a253963e75b761fb6388416b1520e476d133217afd4a1a17d592857a761188` |
| `12_hardening.md`        |   209 | `d53108eb6c11bfcc97c48c243c52df74d1674ed2ad76c59641036b2ad5c6e532e` |
| `13_operations.md`       |   476 | `866dc4782ccfe4b40202d9f45221ec1f7f56f0bfde6ce1c84dbec42af5e6132e` |
| `14_working_with_ai.md`  |   328 | `2443c51763907bf72891c4cb9d35ae458bdfd723ef848e813ea237eb3c21b78a` |
| `AGENTS.md`              |   172 | `17b54479c9c82aa2f7ee471cd0b119977267865928a0b151b27ce5cebbff74a3` |

## Verification

The specification is this repository's own `docs/architecture/`; there is no external copy to
clone or diff against. `npm run docs:check` runs in CI over the rule IDs and citations in these
files (CI runs it via `bin/ci`).
