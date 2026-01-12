-- ============================================================
-- Migration: 020_create_gfx_sessions.sql
-- Description: Supabase 통합 스키마 - gfx_sessions 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- ============================================================

-- gfx_sessions - pokerGFX 세션 데이터
CREATE TABLE IF NOT EXISTS gfx_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    feature_table_id UUID REFERENCES feature_tables(id) ON DELETE SET NULL,

    -- GFX 고유 ID (Windows 파일 시간 형식)
    gfx_id BIGINT UNIQUE NOT NULL,

    -- GFX 메타데이터
    event_title VARCHAR(255),
    table_type VARCHAR(50) NOT NULL,  -- 'FEATURE_TABLE', 'OUTER_TABLE', 'FINAL_TABLE'
    software_version VARCHAR(50),  -- 'PokerGFX 3.2'

    -- 페이아웃 배열
    payouts JSONB DEFAULT '[]',

    -- 상태
    status VARCHAR(20) DEFAULT 'active',  -- 'active', 'completed', 'error'
    total_hands INTEGER DEFAULT 0,

    -- GFX 시간
    created_at_gfx TIMESTAMPTZ,  -- GFX CreatedDateTimeUTC

    -- 파일 정보
    source_file VARCHAR(500),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_gfx_id ON gfx_sessions(gfx_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_tournament ON gfx_sessions(tournament_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_feature ON gfx_sessions(feature_table_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_status ON gfx_sessions(status);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_type ON gfx_sessions(table_type);

-- Comment
COMMENT ON TABLE gfx_sessions IS 'pokerGFX 세션 데이터 (JSON 파일 단위)';
COMMENT ON COLUMN gfx_sessions.gfx_id IS 'pokerGFX ID (Windows 파일 시간 형식, 100ns 단위)';
