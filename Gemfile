source "https://rubygems.org"

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "8.1.4.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft", "1.3.2"
gem "pundit", "2.5.2"
# Use PostgreSQL as the database for Active Record
gem "rack-attack", "6.8.0"
gem "faraday", "2.15.1"
gem "faraday-net_http_persistent", "2.3.1"
gem "net-http-persistent", "4.0.8"
gem "stoplight", "6.0.1"
gem "pg", "1.7.0"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "8.0.2"
# Render React pages from Rails [https://inertiajs.com]
gem "inertia_rails", "3.23.0"
# Build frontend assets with Vite [https://vite-ruby.netlify.app]
gem "vite_rails", "3.11.1"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", "1.2026.6", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache", "1.0.10"
gem "solid_queue", "1.7.2"
gem "solid_cable", "4.1.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", "1.26.1", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", "2.12.0", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", "0.1.27", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "1.14.0"

# Engines are path gems discovered by a glob, so a new module does not edit this file.
Dir[File.join(__dir__, "engines/*/*.gemspec")].sort.each do |gemspec|
  gem File.basename(gemspec, ".gemspec"), path: File.dirname(gemspec)
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", "1.11.1", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", "0.9.3", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "8.1.0", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", "1.1.0", require: false

  gem "flay", "2.14.5", require: false
  gem "packwerk", "3.3.1", require: false
  gem "packwerk-extensions", "0.4.0", require: false
  gem "factory_bot_rails", "6.5.1"
  gem "parallel_tests", "5.9.0"
  gem "rspec-rails", "8.1.0"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console", "4.3.0"
end

group :test do
  gem "json_schemer", "2.5.0"
  gem "webmock", "3.34.0"
end
