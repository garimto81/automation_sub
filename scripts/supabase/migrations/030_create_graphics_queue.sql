-- ============================================================
-- Migration: 030_create_graphics_queue.sql
-- Description: Supabase 통합 스키마 - graphics_queue 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 4 - Broadcast System
-- ============================================================

-- graphics_queue - 그래픽/자막 렌더링 큐
CREATE TABLE IF NOT EXISTS graphics_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    hand_id UUID REFERENCES hands(id) ON DELETE SET NULL,

    -- 그래픽 정보 (26개 자막 유형)
    graphic_type VARCHAR(50) NOT NULL,  -- 'tournament_leaderboard', 'chip_flow', 'elimination_banner' 등
    trigger_event VARCHAR(50) NOT NULL,  -- 'hand_complete', 'level_up', 'elimination' 등

    -- 데이터 페이로드 (자막별 구조)
    payload JSONB NOT NULL DEFAULT '{}',

    -- 우선순위 (1: 최고 ~ 10: 최저)
    priority INTEGER DEFAULT 5,

    -- 상태
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'rendering', 'rendered', 'displayed', 'dismissed', 'error'
    error_message TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    scheduled_at TIMESTAMPTZ,  -- 예약 표시 시간
    rendered_at TIMESTAMPTZ,
    displayed_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_queue_tournament ON graphics_queue(tournament_id);
CREATE INDEX IF NOT EXISTS idx_queue_hand ON graphics_queue(hand_id);
CREATE INDEX IF NOT EXISTS idx_queue_type ON graphics_queue(graphic_type);
CREATE INDEX IF NOT EXISTS idx_queue_status ON graphics_queue(status);
CREATE INDEX IF NOT EXISTS idx_queue_priority ON graphics_queue(priority);
CREATE INDEX IF NOT EXISTS idx_queue_pending ON graphics_queue(status, priority, created_at) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_queue_scheduled ON graphics_queue(scheduled_at) WHERE scheduled_at IS NOT NULL;

-- Comment
COMMENT ON TABLE graphics_queue IS '그래픽/자막 렌더링 큐 (26개 자막 유형)';
COMMENT ON COLUMN graphics_queue.graphic_type IS '자막 유형: tournament_leaderboard, chip_flow, elimination_banner 등';
