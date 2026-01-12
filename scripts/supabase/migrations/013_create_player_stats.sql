-- ============================================================
-- Migration: 013_create_player_stats.sql
-- Description: Supabase 통합 스키마 - player_stats 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 2 - Player System
-- ============================================================

-- player_stats - 플레이어 통계 (토너먼트별)
CREATE TABLE IF NOT EXISTS player_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES player_instances(id) ON DELETE CASCADE,

    -- 핸드 통계
    hands_played INTEGER DEFAULT 0,
    hands_won INTEGER DEFAULT 0,

    -- VPIP/PFR (GFX에서 직접 제공)
    vpip DECIMAL(5,2) DEFAULT 0,
    pfr DECIMAL(5,2) DEFAULT 0,

    -- 고급 통계
    aggression_factor DECIMAL(5,2),
    showdown_win_rate DECIMAL(5,2),
    wtsd DECIMAL(5,2),  -- Went To ShowDown
    three_bet_percentage DECIMAL(5,2),
    fold_to_three_bet DECIMAL(5,2),
    c_bet_percentage DECIMAL(5,2),

    -- All-in 통계
    all_in_count INTEGER DEFAULT 0,
    all_in_won INTEGER DEFAULT 0,

    -- 마지막 계산 시간
    last_calculated_at TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(player_instance_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_player_stats_instance ON player_stats(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_player_stats_vpip ON player_stats(vpip);
CREATE INDEX IF NOT EXISTS idx_player_stats_pfr ON player_stats(pfr);
CREATE INDEX IF NOT EXISTS idx_player_stats_hands ON player_stats(hands_played DESC);

-- Comment
COMMENT ON TABLE player_stats IS '토너먼트별 플레이어 통계 (VPIP, PFR, AF 등)';
COMMENT ON COLUMN player_stats.vpip IS 'Voluntarily Put In Pot - 자발적 팟 참여율 (%)';
COMMENT ON COLUMN player_stats.pfr IS 'Pre-Flop Raise - 프리플랍 레이즈율 (%)';
