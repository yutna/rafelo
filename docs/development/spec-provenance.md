# Spec provenance

The 16 specification files listed below are a read-only copy of the private
Rafelo specification. `docs/architecture/lessons-learned.md` is maintainer
evidence added by this repository; it is not part of the specification copy.

- Source: <https://gist.github.com/yutna/6e3a34d9ee98dff5a00fbefc8bd780ae>
- Commit: `12dd497d7c40f65848efe5d596898497b8c6bc77`
- Imported: 2026-11-12
- Re-synced: 2026-11-16 (from `b9696bba771d633f99c1618c8b00df9e399af5c6`)
- Files: 16
- Lines: 9601

Do not edit these files by hand. When the owner says the gist changed, sync
the copies in a dedicated pull request and update this record. Never push to
the gist.

`docs/architecture/AGENTS.md` is the historical gist copy of the guide, not
the guide any agent loads. OpenCode loads the repository root `AGENTS.md`; the
shipped and corrected guide is that file. The gist copy is preserved verbatim
as part of the read-only specification, including its old "Put secrets or real
personal data in code" sentence. That sentence is not an instruction: the
root guide says "Put no secrets or real personal data in code, tests, fixtures,
logs, or issues" (BE-08). Do not copy the gist sentence into an AI file.

## Verification

```sh
git clone https://gist.github.com/yutna/6e3a34d9ee98dff5a00fbefc8bd780ae.git /tmp/rafelo-spec
diff -r --exclude=.git --exclude=lessons-learned.md /tmp/rafelo-spec docs/architecture
find docs/architecture -maxdepth 1 -name '*.md' ! -name 'lessons-learned.md' \
  -print0 | sort -z | xargs -0 wc -l
find docs/architecture -maxdepth 1 -name '*.md' ! -name 'lessons-learned.md' \
  -print0 | sort -z | xargs -0 sha256sum
```

The diff must be clean, the file count must be 16, and the line count must
be 9601. `lessons-learned.md` is not a specification file, so both commands
exclude it.

## File inventory

| File                     | Lines | SHA-256                                                            |
| ------------------------ | ----: | ------------------------------------------------------------------ |
| `00_README.md`           |   434 | `cf9f021c429d0917c96e5b2399809dd07136554eba5d3fb4c51989f3a76db91f` |
| `01_architecture.md`     |   675 | `40eb45ba64ab16d3af25eb572f15da25370feb6bd1d07e1078251cb80ab9a4f4` |
| `02_backend.md`          |  1295 | `d483745f0049581dbb4385347b9ec8e7803d2d9de920ee8ffc2f48f7d537c3c8` |
| `03_session_security.md` |   596 | `0685a391df29ca4b54bd923bad5d08f1a971c37c7d02b44088ba431eb84c5cab` |
| `04_contracts.md`        |   676 | `8da88d681dd412c42513dc81618639fcf87bedffb6374ffcf26465bd79024459` |
| `05_frontend.md`         |  1082 | `53e889b074cc9c71fd409a11618462143430d64049ef16deb7ed74ba939b565a` |
| `06_frontend_oop.md`     |   378 | `ecab39b8392521a029c4da215258357ef3fd41d39c87b9ef18604a001de3b926` |
| `07_testing.md`          |   572 | `59cbf050d63a0d370885630dd93ca63113cb3164d8573da0121c654097f20efa` |
| `08_generators.md`       |   429 | `6c9560e44edc44f28468a5b2485c6af9131570f919c7019a7915e9699e61395e` |
| `09_enforcement.md`      |  1233 | `a3c7e8d3e1fee28da7a7d5205882712a5827f56a6085d77bbf4a892f4d93b296` |
| `10_decisions.md`        |   564 | `ecc2d662ea84046d3ab5bce858af49fdd406851a6a49377fbff5f590c4f3cae2` |
| `11_workflow.md`         |   482 | `85a253963e75b761fb6388416b1520e476d133217afd4a1a17d592857a761188` |
| `12_hardening.md`        |   209 | `d53108eb6c11bfcc97c48c243c52df74d1674ed2ad76c59641036b2ad5c6e532` |
| `13_operations.md`       |   476 | `866dc4782ccfe4b40202d9f45221ec1f7f56f0bfde6ce1c84dbec42af5e6132e` |
| `14_working_with_ai.md`  |   328 | `2443c51763907bf72891c4cb9d35ae458bdfd723ef848e813ea237eb3c21b78a` |
| `AGENTS.md`              |   172 | `17b54479c9c82aa2f7ee471cd0b119977267865928a0b151b27ce5cebbff74a3` |

## The `b9696bb..12dd497` change

The amended gist changed 14 of the 16 files (+130/−100); `03_session_security.md`
and `06_frontend_oop.md` are unchanged. The change is one review pass:

- **Kernel namespace.** The kernel engines keep `Rafelo::Core` and
  `Rafelo::DesignSystem` (paths `rafelo/core`, `rafelo/design_system`) in every
  adopter (GEN-07, ADR-27); the app namespace (`Acme`) is reserved for the app,
  its product modules and domain engines, the example engines, and everything
  the generators write. Every example that named a kernel constant moved to the
  `Rafelo::` name (01, 02, 04, 05, 07, 08, 09, 10, 12, 14, AGENTS).
- **Own-identity approvals.** An AI agent works under its own GitHub identity
  (a machine user or a GitHub App), never a person's account. `guard_approval`
  and the ratchet approval count only an owner who is not the pull request's
  author, and both read CODEOWNERS and run from the merge base (00, 09, 10, 11,
  14, AGENTS).
- **BE-18 stays as written.** A finished export answers `303` to a short-lived
  signed URL created at click time, kept out of logs by the redaction patch; the
  "downloads stream through core" bullet still covers upstream files only (02,
  09, 12).
- **No missing-path list.** `docs:check` has no list of paths to skip: a missing
  path is created or the text that names it changes (04).
- **CSP report-only is typed.** `csp.report_only` accepts only `true`/`false`,
  defaults to `false`, and drives Rails' report-only setting (02, 12).
- **Amended OPS-09 filter.** The Dev Container image workflow also runs on
  `.ruby-version`, `mise.toml`, and `package-lock.json` (09, 13).
- **Test canaries name the new approval cases.** Author-only approval, a pull
  request that removes its guard path from CODEOWNERS, and a merge-base read
  (07).
