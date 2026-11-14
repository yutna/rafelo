# frozen_string_literal: true

# The Rails application template (GEN-07). It runs inside `rails new <app>`
# with `-d postgresql --devcontainer --skip-javascript --skip-hotwire
# --skip-jbuilder --skip-test -m template/template.rb`.
require_relative "lib/rafelo_template"

RafeloTemplate.assert_flags!(ARGV)
RafeloTemplate.validate!(app_name)

source_root = File.expand_path("..", __dir__)
destination = Dir.pwd
version = File.read(File.join(source_root, "VERSION")).strip

RafeloTemplate.render!(
  source_root: source_root,
  destination: destination,
  app_name: app_name,
  version: version
)
RafeloTemplate.write_kernel_version!(destination: destination, version: version)
RafeloTemplate.write_app_version!(destination: destination)
RafeloTemplate.verify_no_placeholders!(destination)
RafeloTemplate.commit!(destination: destination)

puts "Rafelo template: created #{RafeloTemplate.namespace(app_name)} from v#{version}"
