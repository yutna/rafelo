# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Affected: select", "script/ci/affected --all"
  step "Affected: canaries", "script/ci/affected_canary"

  step "Style: Ruby", "bin/rubocop"
  step "Boundaries: Packwerk validate", "bin/packwerk validate"
  step "Boundaries: Packwerk check", "bin/packwerk check"
  step "Boundaries: Packwerk cycle canary", "script/ci/packwerk_canary"
  step "Boundaries: graph canaries", "script/ci/graph_canaries"
  step "Graph: generated configs", "script/ci/engine_graph --check"
  step "Graph: aliases", "npm run aliases:check"
  step "Growth: budgets", "script/ci/growth"
  step "Growth: fan-in", "script/ci/fan_in"
  step "Growth: fan-in canaries", "script/ci/fan_in_canary"
  step "Growth: canaries", "script/ci/growth_canary"
  step "Clones: cross-engine", "script/ci/clones"
  step "Clones: canaries", "script/ci/clones_canary"
  step "Frontend: Typecheck", "npm run typecheck"
  step "Frontend: Architecture", "npm run arch:check"
  step "Frontend: boundary", "script/ci/frontend_boundary"
  step "Frontend: page props", "script/ci/page_props"
  step "Frontend: state wrappers", "script/ci/frontend_state"
  step "Frontend: state canary", "script/ci/frontend_state_canary"
  step "Frontend: safe URLs", "script/ci/frontend_urls"
  step "Frontend: URL canary", "script/ci/frontend_urls_canary"
  step "Frontend: formatters", "script/ci/frontend_formatters"
  step "Frontend: formatter canary", "script/ci/frontend_formatters_canary"
  step "Enforcement: canaries", "script/ci/enforcement_canaries"
  step "Enforcement: cops", "script/ci/cops_canary"
  step "Tests: skips", "script/ci/skips"
  step "Tests: selectors", "script/ci/test_selectors"
  step "Pins: runtime and packages", "script/ci/pins"
  step "Pins: GitHub Actions", "script/ci/actions_pinned"
  step "Policy: workflows", "script/ci/workflow_policy"
  step "Policy: deploy preflight", "script/ci/deploy_preflight"
  step "Policy: deploy preflight canary", "script/ci/deploy_preflight_canary"
  step "Policy: gem patches", "script/ci/patches"
  step "Policy: gem patches canary", "script/ci/patches_canary"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: npm audit", "npm audit --audit-level=high"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Contracts: check", "npm run contracts:check"
  step "Contracts: errors", "npm run errors:check"
  step "Contracts: i18n", "npm run i18n:check"
  step "Frontend: Build", "npm run build"
  step "Frontend: bundle budget", "script/ci/bundle_budget"
  step "Frontend: Test", "npm test"
  step "Tests: RSpec", "script/ci/rspec"
  step "Tests: page matchers", "npm run pages:check -- --matchers"
  step "Tests: concurrency", "script/ci/concurrency"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
