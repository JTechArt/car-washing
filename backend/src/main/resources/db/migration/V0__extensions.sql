-- Enable pgcrypto to provide gen_random_uuid() on PostgreSQL < 13.
-- On PostgreSQL 13+ this is a no-op (function already built-in).
-- This file is NOT used in H2 tests (tests use db/migration-h2/).
CREATE EXTENSION IF NOT EXISTS pgcrypto;
