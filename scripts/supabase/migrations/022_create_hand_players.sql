-- ============================================================
-- Migration: 022_create_hand_players.sql
-- Description: Supabase 통합 스키마 - hand_players 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- ============================================================

-- hand_players - 핸드별 플레이어 상태
CREATE TABLE IF NOT EXISTS hand_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players_master(id) ON DELETE CASCADE,
    player_instance_id UUID REFERENCES player_instances(id) ON DELETE SET NULL,

    -- GFX 플레이어 정보
    seat_number INTEGER NOT NULL,  -- 1-10

    -- 스택 정보
    start_stack BIGINT NOT NULL,
    end_stack BIGINT NOT NULL,
    stack_delta BIGINT GENERATED ALWAYS AS (end_stack - start_stack) STORED,
    cumulative_winnings BIGINT DEFAULT 0,

    -- 홀 카드 (변환된 형식)
    hole_cards VARCHAR(10),  -- 'AsKh', 'TdTc' 등

    -- 플레이어 상태
    sitting_out BOOLEAN DEFAULT FALSE,
    is_winner BOOLEAN DEFAULT FALSE,

    -- GFX 통계 (핸드 시점)
    vpip_percent DECIMAL(5,2),
    pfr_percent DECIMAL(5,2),
    aggression_percent DECIMAL(5,2),
    wtsd_percent DECIMAL(5,2),

    -- 탈락 정보 (이 핸드에서 탈락 시)
    elimination_rank INTEGER,  -- -1: 미탈락, 1+: 탈락 순위

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(hand_id, seat_number)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hand_players_hand ON hand_players(hand_id);
CREATE INDEX IF NOT EXISTS idx_hand_players_player ON hand_players(player_id);
CREATE INDEX IF NOT EXISTS idx_hand_players_instance ON hand_players(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_hand_players_seat ON hand_players(seat_number);
CREATE INDEX IF NOT EXISTS idx_hand_players_winner ON hand_players(is_winner) WHERE is_winner = TRUE;
CREATE INDEX IF NOT EXISTS idx_hand_players_delta ON hand_players(stack_delta DESC);

-- Comment
COMMENT ON TABLE hand_players IS '핸드별 플레이어 상태 (GFX Player 객체 매핑)';
COMMENT ON COLUMN hand_players.hole_cards IS '홀 카드 (변환됨: as,kh → AsKh)';
COMMENT ON COLUMN hand_players.stack_delta IS '스택 변동 (자동 계산: end_stack - start_stack)';
