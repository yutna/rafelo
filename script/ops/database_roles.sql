-- Two database roles for Rafelo (OPS-08).
--
-- Run once per database as a superuser, with the passwords supplied through
-- psql variables so they never appear in this file:
--
--   psql -v ON_ERROR_STOP=1 \
--     -v runtime_password='...' -v migration_password='...' \
--     -f script/ops/database_roles.sql
--
-- The script is re-runnable. It creates the roles when they are missing,
-- gives the migration role ownership of the tables that already exist (a
-- v0.18.0 database was created by the deploy superuser), and grants the
-- runtime role its DML. Run it before the first `db:prepare` on a fresh
-- database and before the first v0.19.0 deploy on an existing one.
--
-- The migration role owns every table and runs migrations. The runtime role
-- owns none, and on the audit tables it may only INSERT and SELECT.

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rafelo_runtime') THEN
    CREATE ROLE rafelo_runtime LOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rafelo_migrator') THEN
    CREATE ROLE rafelo_migrator LOGIN;
  END IF;
END
$$;

ALTER ROLE rafelo_runtime WITH LOGIN PASSWORD :'runtime_password';
ALTER ROLE rafelo_migrator WITH LOGIN PASSWORD :'migration_password';

-- The admin that runs this script must be able to SET ROLE rafelo_migrator to
-- transfer table ownership and set its default privileges. A managed
-- provider's admin is not a superuser; on PostgreSQL 16+ the role that
-- created rafelo_migrator holds ADMIN OPTION on it, so this grant succeeds.
DO $$
BEGIN
  EXECUTE format('GRANT rafelo_migrator TO %I', current_user);
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE EXCEPTION
      'database_roles: % must be a superuser or hold ADMIN OPTION on rafelo_migrator',
      current_user;
END
$$;

DO $$
BEGIN
  EXECUTE format(
    'GRANT CONNECT ON DATABASE %I TO rafelo_runtime, rafelo_migrator',
    current_database()
  );
END
$$;

GRANT USAGE ON SCHEMA public TO rafelo_runtime, rafelo_migrator;

-- The migration role owns the schema and everything it creates.
ALTER SCHEMA public OWNER TO rafelo_migrator;

-- A database created before this script has tables owned by the deploy
-- superuser. Partition creation and migrations need the owner, so hand every
-- existing table and sequence to the migration role before the first
-- `db:prepare` runs under it.
DO $$
DECLARE
  object_kind "char";
  object_name text;
BEGIN
  FOR object_kind, object_name IN
    SELECT c.relkind, c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p', 'S')
      AND pg_get_userbyid(c.relowner) <> 'rafelo_migrator'
      -- A serial/identity sequence follows its table's owner; changing it
      -- directly is refused while the dependency exists.
      AND NOT (
        c.relkind = 'S' AND EXISTS (
          SELECT 1 FROM pg_depend d
          WHERE d.classid = 'pg_class'::regclass
            AND d.objid = c.oid
            AND d.refclassid = 'pg_class'::regclass
            AND d.deptype = 'a'
        )
      )
  LOOP
    IF object_kind = 'S' THEN
      EXECUTE format('ALTER SEQUENCE public.%I OWNER TO rafelo_migrator', object_name);
    ELSE
      EXECUTE format('ALTER TABLE public.%I OWNER TO rafelo_migrator', object_name);
    END IF;
  END LOOP;
END
$$;

-- Runtime DML outside the audit tables.
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO rafelo_runtime;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rafelo_runtime;

-- Audit tables: append-only through the runtime role. The database trigger
-- is the second guard, so UPDATE/DELETE fail even if a grant is missed. The
-- v0.18.0 release still writes to core_audits during the expand release, so
-- that table gets the same restriction.
DO $$
DECLARE
  table_name text;
BEGIN
  FOR table_name IN
    SELECT c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
      AND (
        c.relname IN ('core_audits', 'core_audit_events')
        OR c.relname ~ '^core_audit_events_'
      )
  LOOP
    EXECUTE format('REVOKE UPDATE, DELETE, TRUNCATE ON public.%I FROM rafelo_runtime', table_name);
    EXECUTE format('GRANT SELECT, INSERT ON public.%I TO rafelo_runtime', table_name);
  END LOOP;
END
$$;

-- Future tables and audit partitions created by the migration role. Set the
-- defaults before the first migration so a fresh database needs no second
-- pass; the partition routine narrows the audit tables after each creation.
ALTER DEFAULT PRIVILEGES FOR ROLE rafelo_migrator IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO rafelo_runtime;
ALTER DEFAULT PRIVILEGES FOR ROLE rafelo_migrator IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO rafelo_runtime;
