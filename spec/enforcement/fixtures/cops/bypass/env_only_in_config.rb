# expected offenses: 9
ENV["SECRET_KEY"]
::ENV["SECRET_KEY"]
ENV.fetch("SECRET_KEY")
ENV.key?("SECRET_KEY")
ENV.to_h
ENV.slice("SECRET_KEY")
ENV["SECRET_KEY"] = "x"
Rails.application.credentials
Rails.application&.credentials
note = "Rails.application.credentials" # ENV in a comment
"ENV in a string"
