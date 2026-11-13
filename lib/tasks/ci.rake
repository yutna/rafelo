# frozen_string_literal: true

namespace :ci do
  desc "Walk the production route set and check it against the committed allow-list"
  task production_routes: :environment do
    routes = Rafelo::Core::ProductionRoutes.walk(
      Rails.application.routes,
      known_engines: Rafelo::Core::Modules.all.map(&:engine)
    )
    modules = Rafelo::Core::ProductionRoutes.module_routes(Rafelo::Core::Modules.all)

    if ENV["DUMP"]
      puts JSON.pretty_generate(
        routes: routes.map(&:to_h),
        module_routes: modules.map(&:to_h)
      )
      next
    end

    allow_list = Rafelo::Core::ProductionRoutes.load_allow_list(
      Rails.root.join("config/production_routes.yml")
    )
    errors = Rafelo::Core::ProductionRoutes.check(
      walked: routes,
      allow_list: allow_list,
      module_routes: modules
    )
    if errors.any?
      errors.each { |error| warn "production_routes: #{error}" }
      abort "production_routes: #{errors.length} route(s) unclassified or missing"
    end

    puts "production_routes: walked #{routes.length} routes, matched #{allow_list.length} listed and #{modules.length} module routes"
  end
end
