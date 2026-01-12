-- ============================================================
-- Migration: 042_create_triggers.sql
-- Description: Supabase 통합 스키마 - Triggers
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 5 - Views & Functions
-- ============================================================

-- ============================================================
-- 1. Chip Flow Trigger
-- ============================================================

-- 플레이어 칩 변동 시 자동으로 chip_flow 기록
CREATE OR REPLACE FUNCTION log_chip_flow()
RETURNS TRIGGER AS $$
DECLARE
    v_level_number INTEGER;
    v_big_blind INTEGER;
BEGIN
    -- 칩 변동이 없으면 무시
    IF OLD.chips = NEW.chips THEN
        RETURN NEW;
    END IF;

    -- 현재 블라인드 레벨 조회
    SELECT bl.level_number, bl.big_blind
    INTO v_level_number, v_big_blind
    FROM blind_levels bl
    WHERE bl.tournament_id = NEW.tournament_id
      AND bl.is_current = TRUE
    LIMIT 1;

    -- chip_flow 기록
    INSERT INTO chip_flow (
        player_instance_id,
        delta,
        reason,
        running_total,
        level_number,
        bb_count,
        source
    ) VALUES (
        NEW.id,
        NEW.chips - OLD.chips,
        CASE
            WHEN NEW.chips > OLD.chips THEN 'pot_win'
            WHEN NEW.chips < OLD.chips THEN 'pot_loss'
            ELSE 'unknown'
        END,
        NEW.chips,
        v_level_number,
        calculate_bb_count(NEW.chips, v_big_blind),
        'trigger'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_chip_flow
    AFTER UPDATE OF chips ON player_instances
    FOR EACH ROW
    EXECUTE FUNCTION log_chip_flow();

-- ============================================================
-- 2. Updated At Trigger
-- ============================================================

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 updated_at 트리거 적용
CREATE TRIGGER trg_venues_updated_at
    BEFORE UPDATE ON venues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_tournaments_updated_at
    BEFORE UPDATE ON tournaments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_players_master_updated_at
    BEFORE UPDATE ON players_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_player_instances_updated_at
    BEFORE UPDATE ON player_instances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_feature_tables_updated_at
    BEFORE UPDATE ON feature_tables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_gfx_sessions_updated_at
    BEFORE UPDATE ON gfx_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_commentators_updated_at
    BEFORE UPDATE ON commentators
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Comment
COMMENT ON FUNCTION log_chip_flow IS '플레이어 칩 변동 시 자동으로 chip_flow 테이블에 기록';
COMMENT ON FUNCTION update_updated_at IS 'updated_at 컬럼 자동 갱신';
