# Database roles

OPS-08 separates the role that owns and migrates the database from the role
the application uses at runtime.

| Role | Used by | Owns tables | Audit tables |
| --- | --- | --- | --- |
| `rafelo_migrator` | `bin/rails db:prepare` in the entrypoint, migrations, the partition routine, backups | Yes | Owns them; may drop whole partitions for retention |
| `rafelo_runtime` | Puma, Solid Queue, consoles | No | `INSERT` and `SELECT` only: no `UPDATE`, `DELETE`, or `TRUNCATE` |

The runtime role cannot disable the append-only trigger without table
ownership, and `TRUNCATE` bypasses row triggers, so it has no `TRUNCATE`
grant either. A superuser or the migration role can still change the table;
that is the documented limit of this control (OPS-08). Audit records that
must survive that threat go to an external append-only store, which is an
adopter decision.

## Create the roles

Run once per database, as a superuser, with the passwords supplied through
psql variables:

```sh
psql -v runtime_password='...' -v migration_password='...' \
  -f script/ops/database_roles.sql
```

Then put the same passwords in the `database.password` and
`database.migration_password` credentials (BE-08) and set `DB_USER`,
`DB_MIGRATION_USER`, and `DB_NAME` in the deploy profile. The entrypoint runs
`db:prepare` with `RAFELO_DATABASE_ROLE=migration`, so only that one command
uses the migration credentials (BE-22).

`AuditPartitions#restrict_grants!` repeats the audit grant on every new
monthly partition, and `script/ops/database_roles.sql` applies it to existing
partitions. A missed grant still cannot make a row mutable: the trigger on
the partitioned parent rejects every `UPDATE` and `DELETE`.

## Verify

```sql
SELECT has_table_privilege('rafelo_runtime', 'core_audit_events', 'INSERT');
SELECT has_table_privilege('rafelo_runtime', 'core_audit_events', 'UPDATE');   -- false
SELECT has_table_privilege('rafelo_runtime', 'core_audit_events', 'DELETE');   -- false
SELECT has_table_privilege('rafelo_runtime', 'core_audit_events', 'TRUNCATE'); -- false
```
