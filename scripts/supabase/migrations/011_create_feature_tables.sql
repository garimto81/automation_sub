-- ============================================================
-- Migration: 011_create_feature_tables.sql
-- Description: Supabase 통합 스키마 - feature_tables 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 2 - Player System
-- ============================================================

-- feature_tables - 피처 테이블 관리
CREATE TABLE IF NOT EXISTS feature_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 테이블 정보
    table_number INTEGER NOT NULL,
    table_name VARCHAR(100),  -- "Amazon Room Table 1"

    -- RFID 연동
    rfid_device_id VARCHAR(100),
    gfx_table_id VARCHAR(100),  -- pokerGFX 테이블 ID

    -- 상태
    is_active BOOLEAN DEFAULT TRUE,
    is_streaming BOOLEAN DEFAULT FALSE,

    -- 카메라/방송 설정
    camera_config JSONB DEFAULT '{}',

    -- 시간 추적
    activated_at TIMESTAMPTZ,
    deactivated_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tournament_id, table_number)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_feature_tables_tournament ON feature_tables(tournament_id);
CREATE INDEX IF NOT EXISTS idx_feature_tables_active ON feature_tables(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_feature_tables_streaming ON feature_tables(is_streaming) WHERE is_streaming = TRUE;
CREATE INDEX IF NOT EXISTS idx_feature_tables_rfid ON feature_tables(rfid_device_id);

-- Comment
COMMENT ON TABLE feature_tables IS '피처 테이블 (RFID 연동, 방송 대상)';
