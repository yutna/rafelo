# expected offenses: 5
Rails.cache
Rails.cache.clear
Rails.cache.delete("key")
Rails.cache.delete(::Rails.cache)
note = "Rails.cache in a string" # Rails.cache in a comment
