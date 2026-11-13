# frozen_string_literal: true

# A migration queued behind a long query fails instead of blocking every
# request; boot-time migrations must fit deploy_timeout (BE-22).
StrongMigrations.lock_timeout = 10.seconds
StrongMigrations.statement_timeout = 5.minutes

# Concurrent index builds are safe to re-run: drop a leftover invalid index
# first, then build it (BE-22). The migration still needs
# disable_ddl_transaction! and algorithm: :concurrently.
StrongMigrations.remove_invalid_indexes = true
