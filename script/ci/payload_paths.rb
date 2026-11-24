# frozen_string_literal: true

# The one predicate for "does the template pay attention to this path?".
#
# `template/lib/rafelo_template.rb` walks the payload to copy a release, and
# `script/ci/kernel_update` walks the same payload to decide which files a
# released app ever received. They must agree: a local `--source` tree holds
# generated and ignored paths (node_modules, tmp, log, storage, public/vite)
# that the template never copies, and the updater must not treat them as
# shipped kernel files (GEN-07).
module Rafelo
  module PayloadPaths
    # Directories and files that never belong to an adopted app.
    DEFAULT_EXCLUDES = %w[
      .git
      .bundle
      node_modules
      tmp
      log
      storage
      test-results
      playwright-report
      blob-report
      coverage
      public/vite
      public/vite-dev
      public/vite-test
    ].freeze

    module_function

    def excluded?(relative, excludes = [])
      relative = relative.to_s
      return true if ignored?(relative)

      Array(excludes).any? do |pattern|
        pattern = pattern.to_s
        relative == pattern ||
          relative.start_with?("#{pattern}/") ||
          File.fnmatch?(pattern, relative, File::FNM_PATHNAME | File::FNM_DOTMATCH)
      end
    end

    def ignored?(relative)
      components = relative.split(File::SEPARATOR)
      return true if (components & DEFAULT_EXCLUDES).any?

      DEFAULT_EXCLUDES.any? { |exclude| relative.start_with?("#{exclude}/") }
    end
  end
end
