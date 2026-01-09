-- ============================================================================
-- Migration: 20260110000000_create_schemas.sql
-- Description: Create 4 separate schemas for WSOP Broadcast Graphics
-- Schemas: ae, json, wsop_plus, manual
-- ============================================================================

-- Create schemas
CREATE SCHEMA IF NOT EXISTS ae;
CREATE SCHEMA IF NOT EXISTS json;
CREATE SCHEMA IF NOT EXISTS wsop_plus;
CREATE SCHEMA IF NOT EXISTS manual;

-- Grant usage to all roles
GRANT USAGE ON SCHEMA ae TO postgres, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA json TO postgres, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA wsop_plus TO postgres, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA manual TO postgres, anon, authenticated, service_role;

-- Default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA ae GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA ae GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA ae GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA json GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA json GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA json GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA wsop_plus GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA wsop_plus GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA wsop_plus GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA manual GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA manual GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA manual GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

-- Default privileges for sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA ae GRANT USAGE ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA json GRANT USAGE ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA wsop_plus GRANT USAGE ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA manual GRANT USAGE ON SEQUENCES TO postgres, anon, authenticated, service_role;

-- Comment on schemas
COMMENT ON SCHEMA ae IS 'After Effects template/composition metadata';
COMMENT ON SCHEMA json IS 'pokerGFX RFID real-time hand data (Feature Table only)';
COMMENT ON SCHEMA wsop_plus IS 'Tournament operations from WSOP+ CSV';
COMMENT ON SCHEMA manual IS 'User-entered master data (profiles, commentators, venues)';
