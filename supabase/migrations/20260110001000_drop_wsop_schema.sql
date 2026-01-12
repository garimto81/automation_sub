-- ============================================================================
-- Migration: 20260110001000_drop_wsop_schema.sql
-- Description: Drop legacy wsop schema (replaced by 4-Schema architecture)
-- ============================================================================

-- Drop the legacy wsop schema and all its objects
DROP SCHEMA IF EXISTS wsop CASCADE;

-- Confirm removal
COMMENT ON SCHEMA ae IS 'After Effects template/composition metadata (replaces wsop)';
COMMENT ON SCHEMA json IS 'pokerGFX RFID real-time hand data (replaces wsop.gfx_*, wsop.hands)';
COMMENT ON SCHEMA wsop_plus IS 'Tournament operations from WSOP+ CSV (replaces wsop.tournaments)';
COMMENT ON SCHEMA manual IS 'User-entered master data (replaces wsop.players_master, wsop.venues)';
