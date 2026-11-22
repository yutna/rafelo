require "rails_helper"
require "fileutils"
require "json"
require "tmpdir"
require Rails.root.join("engines/core/lib/generators/rafelo/base/post_write")
require Rails.root.join("engines/core/lib/generators/rafelo/module_generator")
require Rails.root.join("engines/core/lib/generators/rafelo/domain_generator")
require Rails.root.join("engines/core/lib/generators/rafelo/page_generator")
require Rails.root.join("engines/core/lib/generators/rafelo/rename_module_generator")
require Rails.root.join("engines/core/lib/generators/rafelo/move_page_generator")

FORMATTER = "npx prettier --write"

RSpec.describe "GEN-09 generator post-write order and rollback" do
  def init_repository(root)
    system("git init -q", chdir: root.to_s, exception: true)
    system("git config user.email generator@example.test", chdir: root.to_s, exception: true)
    system("git config user.name Generator", chdir: root.to_s, exception: true)
    system("git add -A", chdir: root.to_s, exception: true)
    system("git commit -qm fixture", chdir: root.to_s, exception: true)
  end

  def git_status(root)
    IO.popen([ "git", "status", "--porcelain", "--untracked-files=all" ], chdir: root.to_s, &:read)
  end

  def write_grants(root)
    FileUtils.mkdir_p(root.join("config"))
    File.write(root.join("config/grants.json"), JSON.pretty_generate("grants" => [ "existing:widgets:read" ]) + "\n")
    FileUtils.mkdir_p(root.join("engines/existing/config"))
    File.write(root.join("engines/existing/config/permissions.yml"), "existing:\n  widgets:\n    - read\n")
  end

  def run_until_failure(generator_class, arguments, root, failed_step)
    commands = []
    failing = Class.new(generator_class) do
      define_method(:run_post_write_step) do |command|
        commands << command
        failed = failed_step.start_with?(FORMATTER) ? command.start_with?(FORMATTER) : command == failed_step
        !failed
      end
    end
    action = {
      Rafelo::Generators::ModuleGenerator => :create_module,
      Rafelo::Generators::DomainGenerator => :create_domain,
      Rafelo::Generators::PageGenerator => :create_page,
      Rafelo::Generators::RenameModuleGenerator => :rename,
      Rafelo::Generators::MovePageGenerator => :move
    }.fetch(generator_class)

    error = nil
    begin
      failing.new(arguments, {}, destination_root: root.to_s).public_send(action)
    rescue SystemExit, Thor::Error => e
      error = e
    end
    [ commands, error ]
  end

  def expect_rollback(generator_class, arguments, fixture, failed_step)
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      fixture.call(root)
      init_repository(root)
      before = git_status(root)
      expect(before).to be_empty

      commands, error = run_until_failure(generator_class, arguments, root, failed_step)

      expect(error).to be_present, "expected the generator to fail at #{failed_step}"
      expect(error.message).to include(failed_step)
      step_index = failed_step == FORMATTER ? Rafelo::Generators::PostWrite::STEPS.length : Rafelo::Generators::PostWrite::STEPS.index(failed_step)
      expect(step_index).not_to be_nil
      expected = Rafelo::Generators::PostWrite::STEPS.take(step_index)
      expect(commands.take(step_index)).to eq(expected)
      expect(commands.length).to eq(step_index + 1)
      expect(git_status(root)).to be_empty, "tree dirty after #{failed_step}:\n#{git_status(root)}"
    end
  end

  it "runs the GEN-09 steps in order and finishes with the formatter" do
    expect(Rafelo::Generators::PostWrite::STEPS).to eq(
      [
        "bundle install",
        "script/ci/engine_graph",
        "npm run aliases:generate",
        "npm run permissions:generate",
        "npm run errors:generate",
        "npm run i18n:generate",
        "npm run contracts:generate"
      ]
    )
  end

  [ Rafelo::Generators::PostWrite::STEPS, FORMATTER ].flatten.each do |step|
    it "rolls the module generator back when #{step} fails" do
      expect_rollback(Rafelo::Generators::ModuleGenerator, [ "rollback_probe" ], method(:write_grants), step)
    end

    it "rolls the domain generator back when #{step} fails" do
      expect_rollback(Rafelo::Generators::DomainGenerator, [ "rollback_domain" ], method(:write_grants), step)
    end

    it "rolls the page generator back when #{step} fails" do
      fixture = lambda do |root|
        write_grants(root)
        FileUtils.mkdir_p(root.join("engines/billing/config/locales"))
        FileUtils.mkdir_p(root.join("engines/billing/config/contracts"))
        File.write(root.join("engines/billing/config/routes.rb"), "Rafelo::Billing::Engine.routes.draw do\nend\n")
        File.write(root.join("engines/billing/config/permissions.yml"), "--- {}\n")
        %w[en th].each do |locale|
          File.write(root.join("engines/billing/config/locales/#{locale}.yml"), "#{locale}:\n  billing: {}\n")
        end
      end
      expect_rollback(Rafelo::Generators::PageGenerator, [ "billing", "widgets" ], fixture, step)
    end

    it "rolls the rename generator back when #{step} fails" do
      fixture = lambda do |root|
        write_grants(root)
        engine = root.join("engines/billing")
        FileUtils.mkdir_p(engine.join("config/initializers"))
        FileUtils.mkdir_p(engine.join("lib/rafelo/billing"))
        File.write(engine.join("package.yml"), YAML.dump("enforce_dependencies" => "strict", "dependencies" => []))
        File.write(engine.join("config/ratchets.yml"), YAML.dump("eslint_disable" => 0))
        File.write(engine.join("config/module.rb"), <<~RUBY)
          Rafelo::Core::Modules.register(
            key: :billing,
            engine: Object,
            path: "/billing",
            permission_prefixes: ["billing"],
            nav: { order: 10, label_key: "billing.nav.title", icon: "folder" }
          )
        RUBY
        File.write(engine.join("config/permissions.yml"), YAML.dump("billing" => { "widgets" => [ "read" ] }))
        File.write(engine.join("lib/rafelo/billing/engine.rb"), "module Rafelo::Billing; class Engine < Rails::Engine; end; end\n")
      end
      expect_rollback(Rafelo::Generators::RenameModuleGenerator, [ "billing", "invoicing" ], fixture, step)
    end

    it "rolls the move generator back when #{step} fails" do
      fixture = lambda do |root|
        write_grants(root)
        source = root.join("engines/billing")
        target = root.join("engines/payments")
        [ source, target ].each { |engine| FileUtils.mkdir_p(engine.join("config")) }
        File.write(source.join("config/routes.rb"), "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\nend\n")
        File.write(source.join("config/permissions.yml"), YAML.dump("billing" => { "widgets" => [ "read" ] }))
        File.write(source.join("config/module.rb"), <<~RUBY)
          Rafelo::Core::Modules.register(
            key: :billing,
            engine: Object,
            path: "/billing",
            permission_prefixes: ["billing"],
            nav: { order: 10 }
          )
        RUBY
        File.write(target.join("config/routes.rb"), "Rafelo::Payments::Engine.routes.draw do\nend\n")
        File.write(target.join("config/permissions.yml"), YAML.dump("payments" => {}))
        File.write(target.join("config/module.rb"), <<~RUBY)
          Rafelo::Core::Modules.register(
            key: :payments,
            engine: Object,
            path: "/payments",
            permission_prefixes: ["payments"],
            nav: { order: 20 }
          )
        RUBY
        page = source.join("app/frontend/pages/widgets")
        FileUtils.mkdir_p(page)
        File.write(page.join("index.tsx"), 'export default "billing/widgets";')
      end
      expect_rollback(Rafelo::Generators::MovePageGenerator, [ "billing", "payments", "widgets" ], fixture, step)
    end
  end
end
