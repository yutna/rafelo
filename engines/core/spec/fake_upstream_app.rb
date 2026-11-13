# frozen_string_literal: true

require "json"

# Serves the committed synthetic responses for one upstream. It scans every
# engine's fixture folder at load, so adding a module does not edit this app.
class FakeUpstreamApp
  FIXTURE_ROOT = Rails.root.join("engines")

  def self.call(env)
    upstream = env["rafelo.upstream"] || "api"
    path = env["PATH_INFO"].to_s.delete_prefix("/")
    file = FIXTURE_ROOT.glob("*/spec/fixtures/upstream/#{upstream}/**/*.json").find do |candidate|
      candidate.to_s.end_with?("/#{path}")
    end
    return [ 404, { "Content-Type" => "application/json" }, [ { error: "not_found" }.to_json ] ] unless file

    [ 200, { "Content-Type" => "application/json" }, [ file.read ] ]
  end
end
