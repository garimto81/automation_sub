-- ============================================================
-- Migration: 023_create_hand_actions.sql
-- Description: Supabase 통합 스키마 - hand_actions 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- ============================================================

-- hand_actions - 핸드 액션 로그
CREATE TABLE IF NOT EXISTS hand_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,
    player_id UUID REFERENCES players_master(id) ON DELETE SET NULL,

    -- 액션 순서
    action_order INTEGER NOT NULL,
    street VARCHAR(20) NOT NULL,  -- 'preflop', 'flop', 'turn', 'river', 'showdown'

    -- GFX Event 매핑
    action VARCHAR(20) NOT NULL,  -- 'fold', 'call', 'raise', 'check', 'bet', 'all-in', 'showdown'
    seat_number INTEGER,

    -- 베팅 정보
    bet_amount DECIMAL(12,2),
    pot_size_after DECIMAL(12,2),

    -- Run It Twice 지원
    board_num INTEGER DEFAULT 0,

    -- Draw 게임용
    num_cards_drawn INTEGER DEFAULT 0,

    -- 시간 (GFX DateTimeUTC - 보통 null)
    action_time TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hand_actions_hand ON hand_actions(hand_id);
CREATE INDEX IF NOT EXISTS idx_hand_actions_player ON hand_actions(player_id);
CREATE INDEX IF NOT EXISTS idx_hand_actions_order ON hand_actions(hand_id, action_order);
CREATE INDEX IF NOT EXISTS idx_hand_actions_street ON hand_actions(street);
CREATE INDEX IF NOT EXISTS idx_hand_actions_action ON hand_actions(action);
CREATE INDEX IF NOT EXISTS idx_hand_actions_allin ON hand_actions(hand_id) WHERE action = 'all-in';

-- Comment
COMMENT ON TABLE hand_actions IS '핸드 액션 로그 (GFX Event 객체 매핑)';
COMMENT ON COLUMN hand_actions.street IS '베팅 라운드: preflop, flop, turn, river, showdown';
COMMENT ON COLUMN hand_actions.action IS 'GFX EventType 매핑: fold, call, raise, check, bet, all-in';
