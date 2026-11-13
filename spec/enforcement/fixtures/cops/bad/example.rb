client = Faraday.new("http://example.test")
client.ssl.verify_mode = OpenSSL::SSL::VERIFY_NONE
Rails.application.config.x.thing = true
Rails.cache.fetch("key") { 1 }
params[:return_to]
