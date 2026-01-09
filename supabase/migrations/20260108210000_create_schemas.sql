-- ============================================================
-- Migration: 20260108210000_create_schemas.sql
-- Description: 스키마 네임스페이스 분리 (aep, wsop)
-- Author: Claude Code
-- Date: 2026-01-08
-- ============================================================

-- 1. 스키마 생성
CREATE SCHEMA IF NOT EXISTS aep;
CREATE SCHEMA IF NOT EXISTS wsop;

-- 2. 스키마 권한 설정
GRANT USAGE ON SCHEMA aep TO postgres, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA wsop TO postgres, anon, authenticated, service_role;

GRANT ALL ON ALL TABLES IN SCHEMA aep TO postgres, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA wsop TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA aep TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA wsop TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA aep TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA wsop TO anon;

-- 기본 권한 (향후 생성될 테이블에도 적용)
ALTER DEFAULT PRIVILEGES IN SCHEMA aep GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA aep GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA aep GRANT SELECT ON TABLES TO anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA wsop GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA wsop GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA wsop GRANT SELECT ON TABLES TO anon;

-- 함수 권한
ALTER DEFAULT PRIVILEGES IN SCHEMA aep GRANT EXECUTE ON FUNCTIONS TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA wsop GRANT EXECUTE ON FUNCTIONS TO postgres, anon, authenticated, service_role;

-- 시퀀스 권한
ALTER DEFAULT PRIVILEGES IN SCHEMA aep GRANT USAGE ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA wsop GRANT USAGE ON SEQUENCES TO postgres, anon, authenticated, service_role;

-- 3. PostgREST가 새 스키마를 인식하도록 설정
-- (Supabase Dashboard > API Settings에서 추가 필요)
COMMENT ON SCHEMA aep IS 'After Effects Project 분석 스키마';
COMMENT ON SCHEMA wsop IS 'WSOP 방송 Caption 시스템 스키마';
