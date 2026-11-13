# Gem patches

One file per gem, named `<gem>.rb`. Each file must say why the patch exists,
link the upstream issue or pull request, and prepend a module to the narrowest
class instead of reopening it. Every patch needs two specs under `spec/patches/`:
`<gem>_spec.rb` for the changed behaviour and `<gem>_version_spec.rb` that
records the gem version the patch was written for through `Gem.loaded_specs`.
`script/ci/patches` enforces both.
