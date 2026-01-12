-- ============================================================
-- Migration: 006_create_commentators.sql
-- Description: Supabase 통합 스키마 - commentators 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- commentators - 코멘테이터 정보
CREATE TABLE IF NOT EXISTS commentators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    credentials TEXT,  -- "3x WSOP Bracelet Winner"
    biography TEXT,
    social_links JSONB DEFAULT '{}',  -- {"twitter": "@...", "instagram": "..."}
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_commentators_name ON commentators(name);
CREATE INDEX IF NOT EXISTS idx_commentators_active ON commentators(is_active) WHERE is_active = TRUE;

-- Comment
COMMENT ON TABLE commentators IS '방송 코멘테이터/해설자 정보';
