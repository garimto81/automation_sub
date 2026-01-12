-- ============================================================
-- Migration: 012_create_player_instances.sql
-- Description: Supabase 통합 스키마 - player_instances 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 2 - Player System
-- Note: 토너먼트별 플레이어 상태 (기존 players 대체)
-- ============================================================

-- player_instances - 토너먼트별 플레이어 인스턴스
-- 동일 플레이어가 여러 토너먼트에 참가하면 인스턴스가 각각 생성됨
CREATE TABLE IF NOT EXISTS player_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players_master(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 현재 상태
    chips BIGINT NOT NULL DEFAULT 0,
    seat_number INTEGER,  -- 1-10
    table_number INTEGER,
    feature_table_id UUID REFERENCES feature_tables(id) ON DELETE SET NULL,

    -- 순위 정보 (실시간 계산)
    current_rank INTEGER,
    rank_change INTEGER DEFAULT 0,
    bb_count DECIMAL(10,2),
    avg_stack_percentage DECIMAL(6,2),

    -- 탈락 정보
    is_eliminated BOOLEAN DEFAULT FALSE,
    eliminated_at TIMESTAMPTZ,
    final_rank INTEGER,
    payout_received DECIMAL(12,2),

    -- 등록 정보
    entry_count INTEGER DEFAULT 1,  -- Re-entry 횟수
    registration_time TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 동일 토너먼트에 동일 플레이어는 하나의 인스턴스만
    UNIQUE(player_id, tournament_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_player_instances_player ON player_instances(player_id);
CREATE INDEX IF NOT EXISTS idx_player_instances_tournament ON player_instances(tournament_id);
CREATE INDEX IF NOT EXISTS idx_player_instances_chips ON player_instances(chips DESC);
CREATE INDEX IF NOT EXISTS idx_player_instances_rank ON player_instances(current_rank);
CREATE INDEX IF NOT EXISTS idx_player_instances_table ON player_instances(table_number, seat_number);
CREATE INDEX IF NOT EXISTS idx_player_instances_feature ON player_instances(feature_table_id) WHERE feature_table_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_player_instances_eliminated ON player_instances(is_eliminated);
CREATE INDEX IF NOT EXISTS idx_player_instances_active ON player_instances(tournament_id) WHERE is_eliminated = FALSE;

-- Comment
COMMENT ON TABLE player_instances IS '토너먼트별 플레이어 인스턴스 - 칩, 좌석, 순위 등 실시간 상태';
COMMENT ON COLUMN player_instances.player_id IS 'players_master FK - 마스터 데이터 참조';
COMMENT ON COLUMN player_instances.chips IS '현재 칩 수량 (BIGINT for large stacks)';
