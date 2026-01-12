-- ============================================================
-- Migration: 031_create_eliminations.sql
-- Description: Supabase 통합 스키마 - eliminations 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 4 - Broadcast System
-- ============================================================

-- eliminations - 탈락 상세 정보
CREATE TABLE IF NOT EXISTS eliminations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES player_instances(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 탈락 핸드 정보
    elimination_hand_id UUID REFERENCES hands(id) ON DELETE SET NULL,
    hand_number INTEGER,

    -- 탈락 정보
    final_rank INTEGER NOT NULL,
    payout_received DECIMAL(12,2) DEFAULT 0,

    -- 승자 정보 (누가 탈락시켰는지)
    eliminated_by_id UUID REFERENCES players_master(id) ON DELETE SET NULL,

    -- 탈락 상황 상세
    final_hand VARCHAR(50),  -- "Pair of Aces"
    losing_hand VARCHAR(50),  -- "Pair of Kings"
    final_chips BIGINT DEFAULT 0,

    -- 시간
    eliminated_at TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_eliminations_instance ON eliminations(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_eliminations_tournament ON eliminations(tournament_id);
CREATE INDEX IF NOT EXISTS idx_eliminations_hand ON eliminations(elimination_hand_id);
CREATE INDEX IF NOT EXISTS idx_eliminations_rank ON eliminations(final_rank);
CREATE INDEX IF NOT EXISTS idx_eliminations_time ON eliminations(eliminated_at DESC);
CREATE INDEX IF NOT EXISTS idx_eliminations_eliminated_by ON eliminations(eliminated_by_id);

-- Comment
COMMENT ON TABLE eliminations IS '플레이어 탈락 상세 정보';
COMMENT ON COLUMN eliminations.eliminated_by_id IS '탈락시킨 플레이어 (승자)';
