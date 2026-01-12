-- ============================================================
-- Migration: 007_create_schedules.sql
-- Description: Supabase 통합 스키마 - schedules 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- schedules - 방송 스케줄
CREATE TABLE IF NOT EXISTS schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    time_start TIME NOT NULL,
    time_end TIME,
    title VARCHAR(255) NOT NULL,
    channel VARCHAR(100),  -- "PokerGO", "CBS Sports"
    is_live BOOLEAN DEFAULT FALSE,
    is_current BOOLEAN DEFAULT FALSE,
    stream_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_schedules_event ON schedules(event_id);
CREATE INDEX IF NOT EXISTS idx_schedules_tournament ON schedules(tournament_id);
CREATE INDEX IF NOT EXISTS idx_schedules_date ON schedules(date);
CREATE INDEX IF NOT EXISTS idx_schedules_current ON schedules(is_current) WHERE is_current = TRUE;
CREATE INDEX IF NOT EXISTS idx_schedules_live ON schedules(is_live) WHERE is_live = TRUE;

-- Comment
COMMENT ON TABLE schedules IS '방송 스케줄 (라이브/리플레이)';
