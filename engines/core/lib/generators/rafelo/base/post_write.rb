# frozen_string_literal: true

require "pathname"
require "shellwords"

module Rafelo
  module Generators
    # GEN-09 gives every generator the same post-write sequence. Keeping the
    # order here makes it executable and testable, and a failure names the step
    # the caller has to fix.
    module PostWrite
      STEPS = [
        "bundle install",
        "script/ci/engine_graph",
        "npm run aliases:generate",
        "npm run permissions:generate",
        "npm run errors:generate",
        "npm run i18n:generate",
        "npm run contracts:generate"
      ].freeze

      FORMATTER_EXTENSIONS = /\.(?:json|md|mts|ts|tsx|ya?ml)\z/

      def run_post_write(root:, formatter_files: [])
        commands = [ *STEPS, formatter_command(formatter_files, root: root) ].compact
        inside(root) do
          commands.each do |command|
            unless run_post_write_step(command)
              raise Thor::Error, "post-write step failed: #{command}"
            end
          end
        end
      end

      def run_post_write_step(command)
        run(command)
      end

      def formatter_command(files, root:)
        paths = files.map(&:to_s).uniq.select do |path|
          File.file?(path) && path.match?(FORMATTER_EXTENSIONS)
        end
        return if paths.empty?

        relative = paths.map do |path|
          Shellwords.escape(Pathname.new(path).relative_path_from(Pathname.new(root)).to_s)
        end
        "npx prettier --write #{relative.join(" ")}"
      end
    end
  end
end
