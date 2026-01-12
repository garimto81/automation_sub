-- ============================================================
-- Migration: 025_create_chip_flow.sql
-- Description: Supabase 통합 스키마 - chip_flow 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- Note: chip_history 대체, running_total 추가
-- ============================================================

-- chip_flow - 칩 흐름 추적 (시계열)
CREATE TABLE IF NOT EXISTS chip_flow (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES player_instances(id) ON DELETE CASCADE,
    hand_id UUID REFERENCES hands(id) ON DELETE SET NULL,

    -- 변동 정보
    delta BIGINT NOT NULL,  -- 변동량 (+/-)
    reason VARCHAR(50),  -- 'pot_win', 'blind', 'ante', 'elimination', 'rebuy', 'addon'
    running_total BIGINT NOT NULL,  -- 변동 후 총 칩

    -- 컨텍스트
    hand_number INTEGER,
    level_number INTEGER,

    -- 계산값
    bb_count DECIMAL(10,2),  -- 현재 BB 기준
    avg_stack_percentage DECIMAL(6,2),  -- 평균 스택 대비 %

    -- 데이터 소스
    source VARCHAR(20) DEFAULT 'gfx',  -- 'gfx', 'rfid', 'manual', 'csv'

    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_chip_flow_instance ON chip_flow(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_chip_flow_hand ON chip_flow(hand_id);
CREATE INDEX IF NOT EXISTS idx_chip_flow_timestamp ON chip_flow(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_chip_flow_hand_number ON chip_flow(hand_number DESC);
CREATE INDEX IF NOT EXISTS idx_chip_flow_reason ON chip_flow(reason);
CREATE INDEX IF NOT EXISTS idx_chip_flow_instance_recent ON chip_flow(player_instance_id, timestamp DESC);

-- Comment
COMMENT ON TABLE chip_flow IS '칩 흐름 시계열 데이터 (chip_history 대체)';
COMMENT ON COLUMN chip_flow.delta IS '칩 변동량 (+: 획득, -: 손실)';
COMMENT ON COLUMN chip_flow.running_total IS '변동 후 총 칩 (누적 합계)';
COMMENT ON COLUMN chip_flow.reason IS '변동 사유: pot_win, blind, ante, elimination, rebuy, addon';
