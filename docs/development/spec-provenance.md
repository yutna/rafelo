# Spec provenance

The 16 specification files listed below are a read-only copy of the private
Rafelo specification. `docs/architecture/lessons-learned.md` is maintainer
evidence added by this repository; it is not part of the specification copy.

- Source: <https://gist.github.com/yutna/6e3a34d9ee98dff5a00fbefc8bd780ae>
- Commit: `b9696bba771d633f99c1618c8b00df9e399af5c6`
- Imported: 2026-11-12
- Files: 16
- Lines: 9571

Do not edit these files by hand. When the owner says the gist changed, sync
the copies in a dedicated pull request and update this record. Never push to
the gist.

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
be 9571. `lessons-learned.md` is not a specification file, so both commands
exclude it.

## File inventory

| File | Lines | SHA-256 |
| --- | ---: | --- |
| `00_README.md` | 433 | `22ddad38ed78287daf739140075ea9449b3728d850458f93604416298656bacd` |
| `01_architecture.md` | 675 | `c17b831175ee64165f24d88646119f913de30eb3b798312673ddab61419ffc91` |
| `02_backend.md` | 1295 | `6f028bb3d3cfddf2e2939cdf66b8a5def4222ccea44bd335f08b818e7cfb1985` |
| `03_session_security.md` | 596 | `0685a391df29ca4b54bd923bad5d08f1a971c37c7d02b44088ba431eb84c5cab` |
| `04_contracts.md` | 675 | `94dc1db2b7633f11bef4b2a26099ef20dcda1acb7d3126d4af074d1b20cf39e2` |
| `05_frontend.md` | 1082 | `ec80ccded3a6e4228bcf0a4d6ffcf72300a41e7027a80403ab93bd031ffd6a23` |
| `06_frontend_oop.md` | 378 | `ecab39b8392521a029c4da215258357ef3fd41d39c87b9ef18604a001de3b926` |
| `07_testing.md` | 572 | `1ed9159753e605cf5cb80543b2c5237ff85bd6553a3fe3aad6b38c66ef8f5783` |
| `08_generators.md` | 424 | `a6a78b7f3e86ab8f683307cb9ae95e8bac4e07cea0f11eec94b916ed87a53543` |
| `09_enforcement.md` | 1233 | `8f276f6885abdb40121fdb04b368ddae741020adaaeea4ee39e4dad93924fb1e` |
| `10_decisions.md` | 558 | `09ceb65eb2e54b7154ab1f26b65c94bdc039df0884df8a8997b57a34f7cf7cd1` |
| `11_workflow.md` | 473 | `5fece3cc74cfd4cb7248dbdaa58fee358a02a103f4adef52879767a042207cdb` |
| `12_hardening.md` | 209 | `7146c6a60a6f38f558ea20b8533f09cefeb12f2346c736ab6c785c7d9d57b386` |
| `13_operations.md` | 473 | `aaf235d810528821421ac360ef3e7ed09b07de8ecdb41098b94751335c0c07e0` |
| `14_working_with_ai.md` | 326 | `8e7d2b562ca2209999245506a2647e8ac8dd84355398c3b6d0819b6a625f1015` |
| `AGENTS.md` | 169 | `d91ccda16456001e5e8ad08bee9bf0c84b4509d573fee4d80d6b8d585fdabd99` |
