# frozen_string_literal: true

# The Rails application template (GEN-07). It runs inside `rails new <app>`
# with `-d postgresql --devcontainer --skip-javascript --skip-hotwire
# --skip-jbuilder --skip-test -m template/template.rb`.
require_relative "lib/rafelo_template"

RafeloTemplate.validate!(app_name)

# The payload renderer and copy steps land here. The payload source is
# `template/`; the template repository's own `.github/` and oss-kit callers
# are not copied. The renderer replaces the app namespace in app-level files
# while keeping the kernel brand `Rafelo` (GEN-07).
