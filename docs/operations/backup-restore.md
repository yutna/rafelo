# Backup, restore, and retention

OPS-07 makes the database recoverable and keeps transient data from growing
without bound. PostgreSQL is the only backed-up data store; Active Storage
exports are short-lived and intentionally not backed up.

## What is kept

| Data                                              | Retention                                                                                                       | How it is removed                                                   |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Audit records (`core_audit_events`)               | 365 days (configured)                                                                                           | Drop whole monthly partitions with the migration role (OPS-08)      |
| Sessions (`core_sessions`)                        | At most the 12-hour absolute lifetime                                                                           | Expired rows deleted in batches every hour by `SessionSweepJob`     |
| Idempotency keys (`core_idempotency_keys`)        | 13 hours: the 12-hour absolute session lifetime plus a one-hour margin; a form token older than this is refused | Expired rows deleted in batches every hour by `IdempotencySweepJob` |
| Exports (`core_exports` and Active Storage files) | 6 hours                                                                                                         | `ExportSweepJob` purges files and rows in batches every hour        |
| Queue (Solid Queue)                               | Finished jobs are transient                                                                                     | `SolidQueue::Job.clear_finished_in_batches` every hour              |
| Cache (Solid Cache)                               | At most 30 days, and at most 256 MB                                                                             | Solid Cache's `max_age` and `max_size`                              |
| Cable (Solid Cable)                               | 1 day                                                                                                           | `message_retention: 1.day`                                          |

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

## Decision record: single-host PITR uses pgBackRest

Status: accepted.

**Context.** The single-host profile runs PostgreSQL as a Kamal accessory on
a named volume (OPS-06). A volume on the serving host is not a backup, and
copying a running data directory is unsafe. The profile therefore needs an
off-host repository, continuous WAL archiving, and a restore path proven by a
drill; the specification leaves the tool to a decision record (OPS-07).

**Decision.** Use pgBackRest for the single-host profile. Run it from a
pinned backup container or a backup host, not from the application image and
not from the database accessory: it owns the stanza, the off-host repository,
the base backups, and the WAL archive. The repository is a second host, an
S3-compatible bucket, or a mounted volume that is not the database volume.
The database runs with `wal_level=replica`, `archive_mode=on`, and an
`archive_command` that writes the repository; keep 14 daily full backups and
14 days of WAL. The multi-host profile keeps the managed provider's PITR
instead.

**Consequences.** The template adds no application dependency, and the
single-host profile gets the same recovery point objective shape as the
managed one. The cost is one more scheduled service to pin, monitor, and drill;
its image or package version, stanza name, repository, and retention are
recorded beside the deploy profile at adoption. Verification is the drill
below, which restores a base backup, replays WAL to a chosen point, and runs
`script/ops/restore_drill` against the scratch database.

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
   RESTORE_DATABASE_URL=postgres://.../acme_scratch \
   RAILS_ENV=production \
   RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
   RAILS_HOSTS=restore.invalid \
   DB_USER=acme_runtime \
   ACME_API_BASE_URL=https://api.example.com \
   ACME_DATABASE_ROLE=migration \
   ACME_RESTORE_CONFIRMED=1 \
     bin/rails rafelo:restore:prepare
   ```

   Run this from the release image or with the deploy profile's `env.clear`
   and `RAILS_MASTER_KEY`, as the command shows. The task opens only
   `RESTORE_DATABASE_URL`; it never uses the serving connection. It refuses to
   run without the URL, the confirmation flag, and the migration role, refuses
   a URL that reaches the live database (it compares the connected server and
   database, not the URL spelling), truncates `core_sessions` on the scratch
   target, and prints that the table is empty. Make the URL connect as the
   migration role; the URL is never printed.

4. Run the drill check, which repeats the truncate and proves the table has
   zero rows:

   ```sh
   RESTORE_DATABASE_URL=postgres://.../acme_scratch \
   RAILS_ENV=production \
   RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
   RAILS_HOSTS=restore.invalid \
   DB_USER=acme_runtime \
   ACME_API_BASE_URL=https://api.example.com \
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
