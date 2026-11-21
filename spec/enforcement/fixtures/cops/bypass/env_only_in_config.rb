# expected offenses: 4
ENV["SECRET_KEY"]
::ENV["SECRET_KEY"]
ENV.fetch("SECRET_KEY")
Rails.application.credentials
Rails.application&.credentials
note = "Rails.application.credentials" # ENV in a comment
"ENV in a string"
