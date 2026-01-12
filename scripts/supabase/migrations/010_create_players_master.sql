-- ============================================================
-- Migration: 010_create_players_master.sql
-- Description: Supabase 통합 스키마 - players_master 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 2 - Player System
-- Note: 기존 players 테이블을 마스터/인스턴스로 분리
-- ============================================================

-- players_master - 플레이어 마스터 (중앙 집중)
-- 동일 플레이어가 여러 토너먼트에 참가해도 마스터 데이터는 하나
CREATE TABLE IF NOT EXISTS players_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 기본 정보
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),  -- 방송용 표시 이름
    nationality CHAR(2),  -- ISO 3166-1 alpha-2
    photo_url TEXT,

    -- 외부 ID (중복 방지용)
    hendon_mob_id VARCHAR(50) UNIQUE,
    gpi_id VARCHAR(50) UNIQUE,

    -- WSOP 성적 (누적)
    wsop_bracelets INTEGER DEFAULT 0,
    wsop_rings INTEGER DEFAULT 0,
    wsop_final_tables INTEGER DEFAULT 0,

    -- 전체 성적 (누적)
    total_earnings DECIMAL(15,2) DEFAULT 0,
    total_final_tables INTEGER DEFAULT 0,

    -- 프로필 정보 (player_profiles 병합)
    biography TEXT,
    notable_wins JSONB DEFAULT '[]',
    hometown VARCHAR(255),
    profession VARCHAR(255),

    -- 소셜 링크
    social_links JSONB DEFAULT '{}',

    -- 키플레이어 태그
    is_key_player BOOLEAN DEFAULT FALSE,
    key_player_reason TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 이름 기반 자동 매칭을 위한 UNIQUE (대소문자 무시)
    CONSTRAINT players_master_name_unique UNIQUE (name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_players_master_name ON players_master(name);
CREATE INDEX IF NOT EXISTS idx_players_master_nationality ON players_master(nationality);
CREATE INDEX IF NOT EXISTS idx_players_master_hendon ON players_master(hendon_mob_id);
CREATE INDEX IF NOT EXISTS idx_players_master_gpi ON players_master(gpi_id);
CREATE INDEX IF NOT EXISTS idx_players_master_bracelets ON players_master(wsop_bracelets DESC);
CREATE INDEX IF NOT EXISTS idx_players_master_earnings ON players_master(total_earnings DESC);
CREATE INDEX IF NOT EXISTS idx_players_master_key ON players_master(is_key_player) WHERE is_key_player = TRUE;

-- Comment
COMMENT ON TABLE players_master IS '플레이어 마스터 테이블 - 토너먼트 독립적인 영구 데이터';
COMMENT ON COLUMN players_master.name IS '플레이어 이름 (GFX Name 매칭 키)';
COMMENT ON COLUMN players_master.display_name IS '방송 표시용 이름 (GFX LongName)';
