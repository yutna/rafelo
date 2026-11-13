# Audit events

`core_audit_events` is the append-only record for OPS-08. It stores only the
allow-listed fields: time, viewer, request id, trace id, truncated IP,
user-agent family, event, outcome, target, resource, action, upstream id,
policy, and page. It never stores passwords, tokens, or request bodies.

## Events

| Event | When | Outcome |
| --- | --- | --- |
| `sign_in` | sign-in succeeds or the upstream refuses it | `success` / `failure` |
| `sign_out` | the viewer signs out | `success` |
| `sign_out_everywhere` | every session of the viewer is revoked | `success` |
| `session_revoked` | a refresh returns `401`, or the resent call gets a second `401` | `failure` |
| `authorization` | a `403` denial, with the policy and page | `failure` |
| `rate_limit` | an authentication or other throttled endpoint hits its limit | `failure` |
| `download` | a streamed download finishes or fails | `success` / `failure` |
| `export` | a streamed export finishes or fails | `success` / `failure` |
| `write` | every write action, with its controller resource and action, or a non-GET that raises | `success` / `failure` |

One request-scoped marker makes exactly one row per audited request: a write
refused with `403` records the denial, not a second write row, and a write
that raises records the failure once. Session-less endpoints record none, and
a read that fails upstream records no write row.

## Partitions

The parent table is partitioned by month on `occurred_at`:

- `core_audit_events_YYYY_MM` for each month;
- `core_audit_events_default` catches a row when its month partition is
  missing, so the insert does not fail.

The routine creates the current and next month plus the default. It runs in
the entrypoint as the migration role before the web server starts, in
development and test at boot, and from `AuditPartitionMaintenanceJob` every
hour in production. The job also drops partitions older than 365 days and
reports when the default holds rows.

### DEFAULT partition holds rows

PostgreSQL refuses to create a month partition while the DEFAULT partition
holds rows that belong in it. Move them without a row `DELETE`:

```sql
-- as the migration role, with the app stopped or writes drained
ALTER TABLE core_audit_events DETACH PARTITION core_audit_events_default;
CREATE TABLE core_audit_events_2026_12
  PARTITION OF core_audit_events
  FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');
INSERT INTO core_audit_events (
  occurred_at, event, outcome, target, viewer_id, request_id, trace_id,
  ip, user_agent_family, resource, action, upstream_id, policy, page,
  created_at, format_version
)
SELECT
  occurred_at, event, outcome, target, viewer_id, request_id, trace_id,
  ip, user_agent_family, resource, action, upstream_id, policy, page,
  created_at, format_version
FROM core_audit_events_default;
DROP TABLE core_audit_events_default;
-- the routine recreates the DEFAULT partition on its next run
```

The alert is a `Rails.error` report (`AuditPartitions::DefaultPartitionOccupied`)
and is on by default in the OPS-03 reporter.

## Append-only and retention

A trigger on the partitioned parent rejects every `UPDATE` and `DELETE` on
every partition. The runtime role has only `INSERT` and `SELECT` on the audit
tables (see [database-roles.md](database-roles.md)); it cannot disable the
trigger or `TRUNCATE`. Retention drops whole partitions, not rows, so it needs
no exception to the trigger and never holds a long lock.

The trigger and partitions cannot be expressed in `schema.rb`; the schema is
kept as `db/structure.sql` with the audit partitions excluded
(`--exclude-table=core_audit_events_*`). The routine creates them in every
database.
