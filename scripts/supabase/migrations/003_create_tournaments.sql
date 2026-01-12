-- ============================================================
-- Migration: 003_create_tournaments.sql
-- Description: Supabase 통합 스키마 - tournaments 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- tournaments - 토너먼트 정보
CREATE TABLE IF NOT EXISTS tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    tournament_number INTEGER,  -- WSOP Event #1, #2, etc.
    buy_in DECIMAL(10,2) NOT NULL,
    starting_chips INTEGER NOT NULL,
    current_level INTEGER DEFAULT 1,
    current_day INTEGER DEFAULT 1,  -- Day 1, 2, 3, Final

    -- 참가자 정보
    registered_players INTEGER DEFAULT 0,
    remaining_players INTEGER DEFAULT 0,
    unique_players INTEGER DEFAULT 0,  -- Re-entry 제외

    -- 상금 정보
    prize_pool DECIMAL(15,2) DEFAULT 0,
    bubble_line INTEGER,
    is_itm BOOLEAN DEFAULT FALSE,

    -- 등록 상태
    is_registration_open BOOLEAN DEFAULT TRUE,
    registration_closes_at TIMESTAMPTZ,

    -- 평균 스택
    avg_stack INTEGER,

    -- 상태
    status VARCHAR(20) DEFAULT 'scheduled',  -- 'scheduled', 'running', 'paused', 'completed'

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_tournaments_event ON tournaments(event_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_status ON tournaments(status);
CREATE INDEX IF NOT EXISTS idx_tournaments_day ON tournaments(current_day);
CREATE INDEX IF NOT EXISTS idx_tournaments_number ON tournaments(tournament_number);

-- Comment
COMMENT ON TABLE tournaments IS '개별 토너먼트 정보 (Main Event, $1500 NLH 등)';
