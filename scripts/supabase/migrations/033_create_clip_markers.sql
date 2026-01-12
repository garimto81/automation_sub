-- ============================================================
-- Migration: 033_create_clip_markers.sql
-- Description: Supabase 통합 스키마 - clip_markers 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 4 - Broadcast System
-- Note: automation_feature_table 통합 - 편집 마커
-- ============================================================

-- clip_markers - 편집 마커 (클립 추출용)
CREATE TABLE IF NOT EXISTS clip_markers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID REFERENCES hands(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,

    -- 마커 정보
    marker_type VARCHAR(50) NOT NULL,  -- 'premium_hand', 'all_in', 'elimination', 'big_pot', 'bluff'
    title VARCHAR(255),
    description TEXT,

    -- 타임코드 (녹화 기준)
    start_timecode VARCHAR(20),  -- "01:23:45:12" (HH:MM:SS:FF)
    end_timecode VARCHAR(20),
    duration_seconds INTEGER,

    -- 핸드 등급
    grade CHAR(1),  -- 'A', 'B', 'C', 'D'

    -- 관련 플레이어
    player_ids JSONB DEFAULT '[]',  -- 관련 플레이어 ID 배열

    -- 클립 메타데이터
    metadata JSONB DEFAULT '{}',  -- {"pot_size": 1000000, "hand_rank": "Full House"}

    -- 내보내기 상태
    is_exported BOOLEAN DEFAULT FALSE,
    exported_at TIMESTAMPTZ,
    export_path TEXT,

    -- 상태
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'reviewed', 'exported', 'rejected'
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_clip_markers_hand ON clip_markers(hand_id);
CREATE INDEX IF NOT EXISTS idx_clip_markers_tournament ON clip_markers(tournament_id);
CREATE INDEX IF NOT EXISTS idx_clip_markers_type ON clip_markers(marker_type);
CREATE INDEX IF NOT EXISTS idx_clip_markers_grade ON clip_markers(grade) WHERE grade IN ('A', 'B');
CREATE INDEX IF NOT EXISTS idx_clip_markers_status ON clip_markers(status);
CREATE INDEX IF NOT EXISTS idx_clip_markers_exported ON clip_markers(is_exported) WHERE is_exported = FALSE;

-- Comment
COMMENT ON TABLE clip_markers IS '편집 마커 (클립 추출 및 하이라이트 생성용)';
COMMENT ON COLUMN clip_markers.start_timecode IS '시작 타임코드: HH:MM:SS:FF 형식';
