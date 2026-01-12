-- ============================================================
-- Migration: 005_create_payouts.sql
-- Description: Supabase 통합 스키마 - payouts 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- payouts - 상금 구조
CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    place_start INTEGER NOT NULL,
    place_end INTEGER NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    percentage DECIMAL(5,2),
    is_current_bubble BOOLEAN DEFAULT FALSE,
    is_reached BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tournament_id, place_start, place_end)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_payouts_tournament ON payouts(tournament_id);
CREATE INDEX IF NOT EXISTS idx_payouts_place ON payouts(place_start, place_end);
CREATE INDEX IF NOT EXISTS idx_payouts_bubble ON payouts(tournament_id) WHERE is_current_bubble = TRUE;

-- Comment
COMMENT ON TABLE payouts IS '토너먼트 상금 구조 (place_start:end 범위)';
