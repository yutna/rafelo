require "rails_helper"
require "open3"
require "tmpdir"

RSpec.describe "Locale enum generation" do
  it "fails when the committed enum drifts from config/locales.yml" do
    Dir.mktmpdir("rafelo-i18n-enum-") do |root|
      FileUtils.mkdir_p(File.join(root, "config", "locales"))
      FileUtils.mkdir_p(File.join(root, "engines"))
      FileUtils.mkdir_p(File.join(root, "app", "frontend", "locales"))
      FileUtils.mkdir_p(File.join(root, "engines", "core", "app", "frontend", "contracts"))
      FileUtils.mkdir_p(File.join(root, "engines", "core", "config", "locales"))
      File.write(File.join(root, "config", "locales.yml"), "available:\n  - en\ndefault: en\n")
      File.write(File.join(root, "config", "locales", "en.yml"), "en:\n  app:\n    hello: Hello\n")
      File.write(File.join(root, "engines", "core", "config", "locales", "en.yml"), "en:\n  core:\n    hello: Hello\n")
      FileUtils.mkdir_p(File.join(root, "engines", "core", "app", "frontend", "locales"))
      catalog = "{\n  \"hello\": \"Hello\"\n}\n"
      File.write(File.join(root, "app", "frontend", "locales", "en.json"), catalog)
      File.write(File.join(root, "engines", "core", "app", "frontend", "locales", "en.json"), catalog)
      enum = File.join(root, "engines", "core", "app", "frontend", "contracts", "locales.generated.ts")
      File.write(enum, "// stale\n")

      command = [
        "npx", "tsx", "--tsconfig", "tsconfig.tooling.json",
        "script/contracts/i18n.mts", "--root", root
      ]

      output, status = Open3.capture2e(*command, "--check")
      expect(status).not_to be_success
      expect(output).to include("locales.generated.ts is stale")

      output, status = Open3.capture2e(*command)
      expect(status).to be_success, output
      expect(File.read(enum)).to include('z.enum(["en"] as const)')

      output, status = Open3.capture2e(*command, "--check")
      expect(status).to be_success, output
    end
  end
end
