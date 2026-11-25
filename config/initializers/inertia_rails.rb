# frozen_string_literal: true

InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  config.encrypt_history = true
  config.always_include_errors_hash = true
  config.use_script_element_for_initial_page = true
  config.prop_transformer = ->(props:) { props.deep_transform_keys { |key| key.to_s.camelize(:lower) } }
  config.flash_keys = [ :notice, :alert ]
  config.version = -> { Rafelo::Core::AssetVersion.call }
  # SEC-12: devtools are development tooling. The env flag may enable them in
  # development, but production never serves their routes.
  config.devtools.enabled = false if Rails.env.production?
end
