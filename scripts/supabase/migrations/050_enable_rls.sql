-- ============================================================
-- Migration: 050_enable_rls.sql
-- Description: Supabase 통합 스키마 - RLS 활성화
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 6 - RLS & Realtime
-- ============================================================

-- ============================================================
-- Enable Row Level Security on all tables
-- ============================================================

-- Core Reference Tables
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE blind_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE commentators ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;

-- Player System Tables
ALTER TABLE players_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_tables ENABLE ROW LEVEL SECURITY;

-- Hand System Tables
ALTER TABLE gfx_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE hands ENABLE ROW LEVEL SECURITY;
ALTER TABLE hand_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE hand_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE hand_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE chip_flow ENABLE ROW LEVEL SECURITY;

-- Broadcast System Tables
ALTER TABLE graphics_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE eliminations ENABLE ROW LEVEL SECURITY;
ALTER TABLE soft_contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE clip_markers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_results ENABLE ROW LEVEL SECURITY;

-- Comment
COMMENT ON TABLE venues IS 'RLS 활성화됨 - 정책 참조: 051_create_rls_policies.sql';
