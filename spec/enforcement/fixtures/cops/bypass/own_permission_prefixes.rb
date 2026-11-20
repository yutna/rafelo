# expected offenses: 0
Rafelo::Core::Modules.register(key: "billing.invoice:create")
Rafelo::Core::Modules.register(key: "module:read", permission_prefixes: ["another:read"])
note = "Rafelo::Core::Modules.register" # another prefix in a comment
"Rafelo::Core::Modules.register(key: \"x\")"
