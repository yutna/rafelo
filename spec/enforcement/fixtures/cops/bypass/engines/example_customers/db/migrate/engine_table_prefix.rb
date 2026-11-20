# expected offenses: 0
# The path-specific behavior (exempt file, engine prefix) is proven by the
# stdin cases in script/ci/cops_canary; this fixture proves the name reaches
# the cop through the load paths.
create_table "users"
create_join_table :permissions, :roles
