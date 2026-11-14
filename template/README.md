# Application template payload

`template/template.rb` is the Rails application template entry point for
GEN-07. `template/payload.yml` is the payload manifest: it names the kernel,
guards, examples, docs and AI files to copy, and how each text file is
rendered.

`template/` also owns the adopter-only files: `.github/` (the template
repository's own oss-kit callers are never copied) and the starter
`adopter/README.md`. The renderer replaces the app namespace in app-level
files while keeping the kernel brand `Rafelo`.

The template derives the app namespace from the app name, refuses the
reserved names and any existing constant before writing, asserts the
`rails new` flag set, writes `KERNEL_VERSION`, fails on a leftover `Acme`,
and ends with an initial commit by `Rafelo template
<template@rafelo.invalid>`.
