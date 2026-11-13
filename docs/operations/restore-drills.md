# Restore drills

Every drill restores a base backup and WAL into a scratch PostgreSQL, runs
`script/ops/restore_drill`, and records what actually happened. A drill fails
when `core_sessions` is not empty after the restore or when the recovered data
does not stop at the chosen point.

| Date (UTC) | Environment | PostgreSQL | Backup | Recovery point (UTC) | Recovery time | Sessions after restore | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-11-13 | Local scratch drill (dummy data) | 18.6 | Base backup + archived WAL | 2026-11-13 22:39:25.268097 | 2 s | 0 | Pass |

## Drill 2026-11-13

- **Setup.** PostgreSQL 18.6 in a scratch container with `wal_level=replica`
  and continuous WAL archiving. `db:prepare` created the schema, then a base
  backup was taken with `pg_basebackup`.
- **Writes.** A `before` marker and one session were inserted, the chosen
  recovery point was recorded, and an `after` marker and a second session were
  inserted.
- **Restore.** The base backup was restored into a separate data directory
  and WAL replayed to the recovery point. Only the `before` marker and one
  session came back; the `after` pair did not.
- **Session emptying.** `script/ops/restore_drill` ran
  `rafelo:restore:prepare` as the migration role and then counted the table.
  It reported `sessions=0`.
- **What it proves.** The backup is restorable to a chosen point, the point is
  respected, and the restore path empties restored sessions before traffic.
- **Not covered.** This was a local drill with dummy data, not a production
  provider restore. The first production drill must be recorded here before
  go-live, with its provider, repository, and real recovery time.
