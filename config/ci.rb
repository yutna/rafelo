# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Affected: select", "script/ci/affected --all"

  step "Style: Ruby", "bin/rubocop"
  step "Enforcement: canaries", "script/ci/enforcement_canaries"
  step "Tests: skips", "script/ci/skips"
  step "Tests: selectors", "script/ci/test_selectors"
  step "Pins: runtime and packages", "script/ci/pins"
  step "Pins: GitHub Actions", "script/ci/actions_pinned"
  step "Policy: workflows", "script/ci/workflow_policy"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: npm audit", "npm audit --audit-level=high"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Frontend: Build", "npm run build"
  step "Frontend: Test", "npm test"
  step "Tests: RSpec", "script/ci/rspec"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
