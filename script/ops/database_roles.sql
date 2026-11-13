-- Two database roles for Rafelo (OPS-08).
--
-- Run once per database as a superuser, with the passwords supplied through
-- psql variables so they never appear in this file:
--
--   psql -v runtime_password='...' -v migration_password='...' \
--     -f script/ops/database_roles.sql
--
-- The migration role owns every table and runs migrations. The runtime role
-- owns none, and on the audit tables it may only INSERT and SELECT.

\set ON_ERROR_STOP on

CREATE ROLE rafelo_runtime LOGIN PASSWORD :'runtime_password';
CREATE ROLE rafelo_migrator LOGIN PASSWORD :'migration_password';

GRANT CONNECT ON DATABASE rafelo_production TO rafelo_runtime, rafelo_migrator;
GRANT USAGE ON SCHEMA public TO rafelo_runtime, rafelo_migrator;

-- The migration role owns what it creates.
ALTER SCHEMA public OWNER TO rafelo_migrator;

-- Runtime DML outside the audit tables.
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO rafelo_runtime;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rafelo_runtime;

-- Audit tables: append-only through the runtime role. The database trigger
-- is the second guard, so UPDATE/DELETE fail even if a grant is missed.
REVOKE UPDATE, DELETE, TRUNCATE ON core_audit_events FROM rafelo_runtime;
GRANT SELECT, INSERT ON core_audit_events TO rafelo_runtime;

DO $$
DECLARE
  partition text;
BEGIN
  FOR partition IN
    SELECT child.relname
    FROM pg_inherits
    JOIN pg_class parent ON parent.oid = pg_inherits.inhparent
    JOIN pg_class child ON child.oid = pg_inherits.inhrelid
    WHERE parent.relname = 'core_audit_events'
  LOOP
    EXECUTE format('REVOKE UPDATE, DELETE, TRUNCATE ON %I FROM rafelo_runtime', partition);
    EXECUTE format('GRANT SELECT, INSERT ON %I TO rafelo_runtime', partition);
  END LOOP;
END
$$;

-- Future tables and audit partitions created by the migration role.
ALTER DEFAULT PRIVILEGES FOR ROLE rafelo_migrator IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO rafelo_runtime;
ALTER DEFAULT PRIVILEGES FOR ROLE rafelo_migrator IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO rafelo_runtime;

-- The partition routine applies the audit restriction to each new partition;
-- this block covers tables that already exist when the roles are introduced.
DO $$
DECLARE
  partition text;
BEGIN
  FOR partition IN
    SELECT child.relname
    FROM pg_inherits
    JOIN pg_class parent ON parent.oid = pg_inherits.inhparent
    JOIN pg_class child ON child.oid = pg_inherits.inhrelid
    WHERE parent.relname = 'core_audit_events'
  LOOP
    EXECUTE format('REVOKE UPDATE, DELETE, TRUNCATE ON %I FROM rafelo_runtime', partition);
    EXECUTE format('GRANT SELECT, INSERT ON %I TO rafelo_runtime', partition);
  END LOOP;
END
$$;
