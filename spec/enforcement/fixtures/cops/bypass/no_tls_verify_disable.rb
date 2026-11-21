# expected offenses: 4
response.verify_mode = OpenSSL::SSL::VERIFY_NONE
ssl = { verify: false }
Faraday.new(url, ssl: { verify: false })
Faraday.new(url, ssl_options: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
note = "verify: false" # verify_mode: VERIFY_NONE in a comment
