-- ============================================================
-- Migration: 021_create_hands.sql
-- Description: Supabase 통합 스키마 - hands 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- ============================================================

-- hands - 핸드 메타정보
CREATE TABLE IF NOT EXISTS hands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gfx_session_id UUID REFERENCES gfx_sessions(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,

    -- 핸드 식별
    hand_number INTEGER NOT NULL,
    table_number INTEGER,

    -- 게임 정보
    game_variant VARCHAR(20) NOT NULL DEFAULT 'HOLDEM',  -- 'HOLDEM', 'OMAHA', 'STUD'
    game_class VARCHAR(20) NOT NULL DEFAULT 'FLOP',  -- 'FLOP', 'DRAW', 'STUD'
    bet_structure VARCHAR(20) NOT NULL DEFAULT 'NOLIMIT',  -- 'NOLIMIT', 'POTLIMIT', 'LIMIT'

    -- 블라인드/버튼 정보
    button_seat INTEGER,
    small_blind_seat INTEGER,
    big_blind_seat INTEGER,
    small_blind_amount DECIMAL(12,2),
    big_blind_amount DECIMAL(12,2),
    ante_amount DECIMAL(12,2) DEFAULT 0,
    ante_type VARCHAR(30),  -- 'BB_ANTE_BB1ST', 'ANTE_ALL'
    level_number INTEGER,

    -- 팟/보드 정보
    pot_size DECIMAL(12,2),
    num_boards INTEGER DEFAULT 1,
    run_it_num_times INTEGER DEFAULT 1,

    -- 승자 정보
    winner_id UUID REFERENCES players_master(id) ON DELETE SET NULL,
    winning_hand VARCHAR(50),  -- 'Full House', 'Flush' 등

    -- 등급 (automation_feature_table 통합)
    grade CHAR(1),  -- 'A', 'B', 'C', 'D'
    is_premium BOOLEAN DEFAULT FALSE,  -- Grade A/B
    grade_factors JSONB DEFAULT '{}',  -- {"pot_size": true, "all_in": true, "premium_hand": false}

    -- 시간 정보
    duration INTERVAL,  -- GFX Duration (ISO 8601)
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hands_gfx_session ON hands(gfx_session_id);
CREATE INDEX IF NOT EXISTS idx_hands_tournament ON hands(tournament_id);
CREATE INDEX IF NOT EXISTS idx_hands_number ON hands(hand_number);
CREATE INDEX IF NOT EXISTS idx_hands_grade ON hands(grade) WHERE grade IN ('A', 'B');
CREATE INDEX IF NOT EXISTS idx_hands_premium ON hands(is_premium) WHERE is_premium = TRUE;
CREATE INDEX IF NOT EXISTS idx_hands_winner ON hands(winner_id);
CREATE INDEX IF NOT EXISTS idx_hands_started ON hands(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_hands_session_number ON hands(gfx_session_id, hand_number);

-- Comment
COMMENT ON TABLE hands IS '핸드 메타정보 (GFX Hand 객체 매핑)';
COMMENT ON COLUMN hands.grade IS '핸드 등급: A(최상), B(상), C(중), D(하)';
