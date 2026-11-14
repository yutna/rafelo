# Application template payload

`template/template.rb` is the Rails application template entry point for
GEN-07. `template/` is the payload source; the template repository's own
`.github/` workflows and oss-kit callers are not copied into an adopted app.

The template derives the app namespace from the app name, refuses the
reserved names and any existing constant, copies and renders the kernel,
guards, examples, docs, AI files, and adopter `.github/`, writes
`KERNEL_VERSION`, and ends with an initial commit.
