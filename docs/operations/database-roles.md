# Database roles

OPS-08 separates the role that owns and migrates the database from the role
the application uses at runtime.

| Role | Used by | Owns tables | Audit tables |
| --- | --- | --- | --- |
| `acme_migrator` | `bin/rails db:prepare` in the entrypoint, migrations, the partition routine, backups | Yes | Owns them; may drop whole partitions for retention |
| `acme_runtime` | Puma, Solid Queue, consoles | No | `INSERT` and `SELECT` only: no `UPDATE`, `DELETE`, or `TRUNCATE` |

The runtime role cannot disable the append-only trigger without table
ownership, and `TRUNCATE` bypasses row triggers, so it has no `TRUNCATE`
grant either. A superuser or the migration role can still change the table;
that is the documented limit of this control (OPS-08). Audit records that
must survive that threat go to an external append-only store, which is an
adopter decision.

## Create the roles

Run once per database, as a role that can create roles and administer the
database: the single-host accessory's `postgres` superuser, or the managed
provider's admin. The admin must own the database (or be a superuser) and, on
PostgreSQL 16+, holds `ADMIN OPTION` on the roles it creates; the script
grants itself membership in `acme_migrator` so it can transfer table
ownership. Supply the passwords through psql variables:

```sh
psql -v ON_ERROR_STOP=1 \
  -v runtime_password='...' -v migration_password='...' \
  -f script/ops/database_roles.sql
```

The script is re-runnable. Run it before the first `db:prepare` on a fresh
database, and before the first v0.19.0 deploy on an existing one. It creates
the roles when they are missing, gives the migration role ownership of the
tables and sequences that already exist (a pre-v0.19.0 database was created by
the deploy superuser), grants the runtime role its DML, and applies the
audit-only `INSERT`/`SELECT` grants to `core_audits` as well as
`core_audit_events`.

Then put the same passwords in the `database.password` and
`database.migration_password` credentials (BE-08) and set `DB_USER`,
`DB_MIGRATION_USER`, and `DB_NAME` in the deploy profile. The entrypoint runs
`db:prepare` with `ACME_DATABASE_ROLE=migration`, so only that one command
uses the migration credentials (BE-22).

`AuditPartitions#restrict_grants!` repeats the audit grant on every new
monthly partition, and `script/ops/database_roles.sql` applies it to existing
partitions. A missed grant still cannot make a row mutable: the trigger on
the partitioned parent rejects every `UPDATE` and `DELETE`.

## Verify

```sql
SELECT has_table_privilege('acme_runtime', 'core_audit_events', 'INSERT');
SELECT has_table_privilege('acme_runtime', 'core_audit_events', 'UPDATE');   -- false
SELECT has_table_privilege('acme_runtime', 'core_audit_events', 'DELETE');   -- false
SELECT has_table_privilege('acme_runtime', 'core_audit_events', 'TRUNCATE'); -- false
```

During the expand release the v0.18.0 containers still write to
`core_audits`; the same four statements must hold for that table until the
contract release drops it.
