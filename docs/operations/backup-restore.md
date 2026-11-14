# Backup, restore, and retention

OPS-07 makes the database recoverable and keeps transient data from growing
without bound. PostgreSQL is the only backed-up data store; Active Storage
exports are short-lived and intentionally not backed up.

## What is kept

| Data | Retention | How it is removed |
| --- | --- | --- |
| Audit records (`core_audit_events`) | 365 days (configured) | Drop whole monthly partitions with the migration role (OPS-08) |
| Sessions (`core_sessions`) | At most the 12-hour absolute lifetime | Expired rows deleted in batches every hour by `SessionSweepJob` |
| Idempotency keys (`core_idempotency_keys`) | 13 hours: the 12-hour absolute session lifetime plus a one-hour margin; a form token older than this is refused | Expired rows deleted in batches every hour by `IdempotencySweepJob` |
| Exports (`core_exports` and Active Storage files) | 6 hours | `ExportSweepJob` purges files and rows in batches every hour |
| Queue (Solid Queue) | Finished jobs are transient | `SolidQueue::Job.clear_finished_in_batches` every hour |
| Cache (Solid Cache) | At most 30 days, and at most 256 MB | Solid Cache's `max_age` and `max_size` |
| Cable (Solid Cable) | 1 day | `message_retention: 1.day` |

Every purge uses `in_batches`; audit retention drops a partition instead of
running one long `DELETE`. No purge holds a lock across a large table.

## Point-in-time recovery

PostgreSQL must run with continuous WAL archiving and regular base backups
stored off the host. Never copy the data directory of a running database.

**Single host (Kamal accessory).** Use pgBackRest with an off-host repository:
a second host, an S3-compatible bucket, or a mounted backup volume that is not
the database volume. A minimal stanza:

```ini
[acme]
pg1-path=/var/lib/postgresql/18/docker
repo1-path=/backup/acme
repo1-retention-full=14
repo1-retention-archive=14
archive-async=y
```

`pg1-path` is the data directory of the pinned `postgres:18.6` accessory
image (`SHOW data_directory` reports `/var/lib/postgresql/18/docker`; the
volume mounts at `/var/lib/postgresql`). The database server runs with
`archive_mode=on`, an `archive_command` that writes to `repo1`, and
`wal_level=replica`. Keep at least 14 daily full backups and enough WAL to
cover the retention window. The backup repository must live off the database
host; a volume on the same host is not a backup.

**Multi host or managed PostgreSQL.** Turn on the provider's point-in-time
recovery, set the same 14-day retention, and record the provider's restore
procedure in this file. The application-side steps below do not change.

## Restore procedure

1. Choose the recovery point. It must be after the base backup's consistent
   point and before the incident's first bad write.
2. Restore the base backup and replay WAL into a **scratch** database, never
   over the serving database. With pgBackRest:

   ```sh
   pgbackrest --stanza=acme --type=time \
     --target="2026-11-13 22:39:25.268097+00" --target-action=promote restore
   ```

   Restore into a new data directory and start a separate PostgreSQL on a
   scratch port or host.
3. Before the app takes traffic, empty every restored session. Sessions
   revoked after the recovery point would otherwise work again until their
   absolute expiry (SEC-16). Run with the migration role, which owns the
   table:

   ```sh
   RESTORE_DATABASE_URL=postgres://.../acme \
   RAILS_ENV=production \
   ACME_DATABASE_ROLE=migration \
   ACME_RESTORE_CONFIRMED=1 \
     bin/rails rafelo:restore:prepare
   ```

   The task refuses to run without the confirmation flag and the migration
   role, truncates `core_sessions`, and prints that the table is empty. Make
   `RESTORE_DATABASE_URL` connect as the migration role (or use `DB_HOST`,
   `DB_PORT`, and `DB_NAME` so the role switch in `config/database.yml`
   applies); the URL is never printed.
4. Run the drill check, which repeats the truncate and proves the table has
   zero rows:

   ```sh
   RESTORE_DATABASE_URL=postgres://.../acme \
   RAILS_ENV=production \
   RESTORE_RECOVERY_POINT="2026-11-13 22:39:25.268097+00" \
   RESTORE_EXPECTED_ROLE=acme_migrator \
     script/ops/restore_drill
   ```

5. Verify the marker rows or a known record, point the app at the restored
   database (or promote it), and only then allow traffic.
6. Record the date, environment, PostgreSQL version, backup type, recovery
   point, recovery time, and the post-restore session count in
   [restore-drills.md](restore-drills.md).

## Drill schedule

Run a drill at least monthly and before go-live, in a scratch environment:
restore a base backup, choose a point between two known writes, replay WAL,
run `script/ops/restore_drill`, and record the result. A drill that leaves any
session row fails. The drill records the recovery point and the recovery time
actually achieved, not the target.
Audit records in the restored database must survive the restore; dropping
partitions is retention, not restoration. Review the audit partition routine
when the drill runs (OPS-08).
