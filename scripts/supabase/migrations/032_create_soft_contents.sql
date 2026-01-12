-- ============================================================
-- Migration: 032_create_soft_contents.sql
-- Description: Supabase 통합 스키마 - soft_contents 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 4 - Broadcast System
-- ============================================================

-- soft_contents - 소프트 콘텐츠 큐 (Player Intro, Interview 등)
CREATE TABLE IF NOT EXISTS soft_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    player_id UUID REFERENCES players_master(id) ON DELETE SET NULL,

    -- 콘텐츠 타입
    content_type VARCHAR(50) NOT NULL,  -- 'player_intro', 'hand_highlight', 'interview', 'special_moment'

    -- 콘텐츠 정보
    title VARCHAR(255),
    description TEXT,
    payload JSONB DEFAULT '{}',

    -- 미디어
    media_url TEXT,
    thumbnail_url TEXT,
    duration_seconds INTEGER,

    -- 스케줄
    scheduled_at TIMESTAMPTZ,
    displayed_at TIMESTAMPTZ,

    -- 우선순위
    priority INTEGER DEFAULT 5,

    -- 상태
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'displayed', 'skipped'

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_soft_contents_tournament ON soft_contents(tournament_id);
CREATE INDEX IF NOT EXISTS idx_soft_contents_player ON soft_contents(player_id);
CREATE INDEX IF NOT EXISTS idx_soft_contents_type ON soft_contents(content_type);
CREATE INDEX IF NOT EXISTS idx_soft_contents_status ON soft_contents(status);
CREATE INDEX IF NOT EXISTS idx_soft_contents_scheduled ON soft_contents(scheduled_at) WHERE scheduled_at IS NOT NULL;

-- Comment
COMMENT ON TABLE soft_contents IS '소프트 콘텐츠 (Player Intro, Interview, Hand Highlight 등)';
