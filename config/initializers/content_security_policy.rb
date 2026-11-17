# frozen_string_literal: true

Rails.application.configure do
  # Content-Security-Policy-Report-Only is one typed setting (BE-08, SEC-05):
  # only true or false, default false (enforce). Staging and the Playwright
  # smoke job set CSP_REPORT_ONLY=true; a malformed value fails boot.
  report_only =
    case ENV["CSP_REPORT_ONLY"]
    when nil, "false" then false
    when "true" then true
    else raise "CSP_REPORT_ONLY must be true or false"
    end

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self, :data
    policy.img_src :self, :data
    policy.object_src :none
    policy.script_src :self
    policy.style_src :self
    policy.connect_src :self
    policy.base_uri :self
    policy.form_action :self
    policy.frame_ancestors :none
    # Reports go to the tokenless core endpoint; the smoke job runs with
    # Report-Only and fails when one arrives (SEC-05).
    policy.report_uri "/core/csp_reports"
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.urlsafe_base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
  config.content_security_policy_report_only = report_only
end
