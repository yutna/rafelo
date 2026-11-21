# expected offenses: 3
Faraday::Client.new
Faraday.new
Faraday::Connection.new("https://example.test").get("/")
note = "Faraday in a string" # Faraday in a comment
"Faraday.new"
