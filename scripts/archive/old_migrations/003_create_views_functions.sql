-- ============================================================
-- Migration: 003_create_views_functions.sql
-- Description: 자막 시스템 View 및 유틸리티 함수
-- Author: Claude Code
-- Date: 2026-01-06
-- PRD: PRD-0004 Caption Database Schema
-- Depends: 001_create_caption_tables.sql, 002_extend_gfx_schema.sql
-- ============================================================

BEGIN;

-- ============================================================
-- 1. Leaderboard Views
-- ============================================================

-- 1.1 Tournament Leaderboard View (전체 순위표)
CREATE OR REPLACE VIEW v_tournament_leaderboard AS
SELECT
    p.id,
    p.tournament_id,
    p.name,
    p.nationality,
    p.photo_url,
    p.chips,
    p.current_rank,
    p.rank_change,
    p.bb_count,
    p.avg_stack_percentage,
    p.is_feature_table,
    p.table_number,
    p.seat_number,
    t.current_level,
    bl.big_blind
FROM players p
JOIN tournaments t ON p.tournament_id = t.id
LEFT JOIN blind_levels bl ON t.id = bl.tournament_id AND bl.is_current = TRUE
WHERE p.is_eliminated = FALSE
ORDER BY p.chips DESC;

-- 1.2 Feature Table Players View (피처 테이블 플레이어)
CREATE OR REPLACE VIEW v_feature_table_players AS
SELECT
    p.id,
    p.tournament_id,
    p.name,
    p.nationality,
    p.photo_url,
    p.chips,
    p.seat_number,
    p.table_number,
    ft.table_name,
    ft.is_live,
    pp.wsop_bracelets,
    pp.total_earnings,
    pp.is_key_player,
    pp.key_player_reason,
    ps.vpip,
    ps.pfr,
    ps.aggression_factor
FROM players p
LEFT JOIN feature_tables ft ON p.feature_table_id = ft.id
LEFT JOIN player_profiles pp ON p.id = pp.player_id
LEFT JOIN player_stats ps ON p.id = ps.player_id AND p.tournament_id = ps.tournament_id
WHERE p.is_feature_table = TRUE
  AND p.is_eliminated = FALSE
ORDER BY p.chips DESC;

-- 1.3 Mini Chip Counts View (미니 칩 카운트)
CREATE OR REPLACE VIEW v_mini_chip_counts AS
SELECT
    p.id,
    p.name,
    p.nationality,
    p.chips,
    p.current_rank,
    p.rank_change,
    p.bb_count,
    CASE
        WHEN p.rank_change > 0 THEN 'up'
        WHEN p.rank_change < 0 THEN 'down'
        ELSE 'flat'
    END as trend
FROM players p
WHERE p.is_feature_table = TRUE
  AND p.is_eliminated = FALSE
ORDER BY p.chips DESC;

-- ============================================================
-- 2. Player Info Views
-- ============================================================

-- 2.1 Player Profile View (플레이어 프로필)
CREATE OR REPLACE VIEW v_player_profile AS
SELECT
    p.id,
    p.tournament_id,
    p.name,
    p.nationality,
    p.photo_url,
    p.chips,
    p.current_rank,
    p.bb_count,
    pp.wsop_bracelets,
    pp.wsop_rings,
    pp.total_earnings,
    pp.final_tables,
    pp.hometown,
    pp.profession,
    pp.biography,
    pp.notable_wins,
    pp.is_key_player,
    pp.key_player_reason,
    ps.vpip,
    ps.pfr,
    ps.aggression_factor,
    ps.hands_played
FROM players p
LEFT JOIN player_profiles pp ON p.id = pp.player_id
LEFT JOIN player_stats ps ON p.id = ps.player_id AND p.tournament_id = ps.tournament_id;

-- 2.2 At Risk Players View (탈락 위기 플레이어)
CREATE OR REPLACE VIEW v_at_risk_players AS
SELECT
    p.id,
    p.tournament_id,
    p.name,
    p.nationality,
    p.chips,
    p.current_rank,
    p.bb_count,
    pay.amount as payout_at_risk
FROM players p
JOIN tournaments t ON p.tournament_id = t.id
LEFT JOIN payouts pay ON t.id = pay.tournament_id
    AND p.current_rank BETWEEN pay.place_start AND pay.place_end
WHERE p.is_eliminated = FALSE
  AND p.bb_count < 10  -- Less than 10 BB
ORDER BY p.bb_count ASC;

-- 2.3 Recent Eliminations View (최근 탈락자)
CREATE OR REPLACE VIEW v_recent_eliminations AS
SELECT
    e.id,
    e.tournament_id,
    p.name,
    p.nationality,
    p.photo_url,
    e.final_rank,
    e.payout_received,
    ep.name as eliminated_by_name,
    e.player_hole_cards,
    e.eliminator_hole_cards,
    e.eliminated_at,
    e.was_broadcast
FROM eliminations e
JOIN players p ON e.player_id = p.id
LEFT JOIN players ep ON e.eliminated_by_id = ep.id
ORDER BY e.eliminated_at DESC;

-- ============================================================
-- 3. Statistics Views
-- ============================================================

-- 3.1 Chip Flow View (칩 흐름)
CREATE OR REPLACE VIEW v_chip_flow AS
SELECT
    ch.player_id,
    p.name,
    p.nationality,
    ch.hand_number,
    ch.chips,
    ch.chips_change,
    ch.bb_count,
    ch.avg_stack_percentage,
    ch.timestamp
FROM chip_history ch
JOIN players p ON ch.player_id = p.id
WHERE p.is_feature_table = TRUE
ORDER BY ch.player_id, ch.hand_number DESC;

-- 3.2 VPIP Stats View (VPIP/PFR 통계)
CREATE OR REPLACE VIEW v_vpip_stats AS
SELECT
    ps.player_id,
    p.name,
    p.nationality,
    ps.vpip,
    ps.pfr,
    ps.aggression_factor,
    ps.hands_played,
    CASE
        WHEN ps.vpip < 10 THEN 'tight'
        WHEN ps.vpip > 45 THEN 'loose'
        ELSE 'normal'
    END as play_style
FROM player_stats ps
JOIN players p ON ps.player_id = p.id
WHERE p.is_eliminated = FALSE;

-- 3.3 Hand Players View (핸드별 플레이어 상태)
CREATE OR REPLACE VIEW v_hand_summary AS
SELECT
    h.id as hand_id,
    h.hand_number,
    h.table_number,
    h.game_variant,
    h.pot_size,
    h.started_at,
    h.duration,
    h.status,
    array_agg(
        json_build_object(
            'seat', hp.seat_number,
            'name', p.name,
            'hole_cards', hp.hole_cards,
            'start_stack', hp.start_stack,
            'end_stack', hp.end_stack,
            'is_winner', hp.is_winner
        ) ORDER BY hp.seat_number
    ) as players
FROM hands h
JOIN hand_players hp ON h.id = hp.hand_id
JOIN players p ON hp.player_id = p.id
GROUP BY h.id, h.hand_number, h.table_number, h.game_variant,
         h.pot_size, h.started_at, h.duration, h.status;

-- ============================================================
-- 4. Event & L-Bar Views
-- ============================================================

-- 4.1 Current Blind Level View
CREATE OR REPLACE VIEW v_current_blind_level AS
SELECT
    bl.tournament_id,
    bl.level_number,
    bl.small_blind,
    bl.big_blind,
    bl.ante,
    bl.big_blind_ante,
    bl.duration_minutes,
    bl.started_at,
    bl.ends_at,
    EXTRACT(EPOCH FROM (bl.ends_at - CURRENT_TIMESTAMP)) / 60 as minutes_remaining,
    nbl.small_blind as next_small_blind,
    nbl.big_blind as next_big_blind,
    nbl.ante as next_ante
FROM blind_levels bl
LEFT JOIN blind_levels nbl ON bl.tournament_id = nbl.tournament_id
    AND nbl.level_number = bl.level_number + 1
WHERE bl.is_current = TRUE;

-- 4.2 L-Bar Standard View
CREATE OR REPLACE VIEW v_l_bar_standard AS
SELECT
    t.id as tournament_id,
    t.name as tournament_name,
    t.remaining_players,
    t.avg_stack,
    bl.small_blind || '/' || bl.big_blind ||
        CASE WHEN bl.ante > 0 THEN ' (' || bl.ante || ')' ELSE '' END as blinds,
    t.current_level,
    bl.ends_at as level_ends_at,
    s.event_name as schedule_info
FROM tournaments t
JOIN blind_levels bl ON t.id = bl.tournament_id AND bl.is_current = TRUE
LEFT JOIN schedules s ON s.is_current = TRUE
WHERE t.status = 'running';

-- ============================================================
-- 5. Utility Functions
-- ============================================================

-- 5.1 카드 변환 함수 (GFX → DB 형식)
CREATE OR REPLACE FUNCTION convert_gfx_card(gfx_card TEXT)
RETURNS TEXT AS $$
DECLARE
    rank_part TEXT;
    suit_part TEXT;
BEGIN
    -- Extract suit (last character)
    suit_part := LOWER(RIGHT(gfx_card, 1));

    -- Extract rank (everything except last character)
    rank_part := UPPER(LEFT(gfx_card, LENGTH(gfx_card) - 1));

    -- Convert 10 to T
    IF rank_part = '10' THEN
        rank_part := 'T';
    END IF;

    RETURN rank_part || suit_part;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5.2 홀 카드 변환 함수 (GFX 배열 → DB 문자열)
CREATE OR REPLACE FUNCTION convert_gfx_hole_cards(gfx_cards JSONB)
RETURNS TEXT AS $$
DECLARE
    card1 TEXT;
    card2 TEXT;
BEGIN
    IF gfx_cards IS NULL OR jsonb_array_length(gfx_cards) < 2 THEN
        RETURN NULL;
    END IF;

    card1 := convert_gfx_card(gfx_cards->>0);
    card2 := convert_gfx_card(gfx_cards->>1);

    RETURN card1 || card2;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5.3 BB 계산 함수
CREATE OR REPLACE FUNCTION calculate_bb_count(
    chips INTEGER,
    big_blind INTEGER
)
RETURNS DECIMAL(10,2) AS $$
BEGIN
    IF big_blind IS NULL OR big_blind = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(chips::DECIMAL / big_blind, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5.4 평균 스택 대비 퍼센트 계산 함수
CREATE OR REPLACE FUNCTION calculate_avg_stack_percentage(
    chips INTEGER,
    avg_stack INTEGER
)
RETURNS DECIMAL(6,2) AS $$
BEGIN
    IF avg_stack IS NULL OR avg_stack = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(chips::DECIMAL / avg_stack * 100, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5.5 순위 업데이트 함수
CREATE OR REPLACE FUNCTION update_player_ranks(p_tournament_id UUID)
RETURNS VOID AS $$
BEGIN
    WITH ranked AS (
        SELECT
            id,
            current_rank as old_rank,
            ROW_NUMBER() OVER (ORDER BY chips DESC) as new_rank
        FROM players
        WHERE tournament_id = p_tournament_id
          AND is_eliminated = FALSE
    )
    UPDATE players p
    SET
        current_rank = r.new_rank,
        rank_change = COALESCE(r.old_rank, r.new_rank) - r.new_rank,
        updated_at = CURRENT_TIMESTAMP
    FROM ranked r
    WHERE p.id = r.id;
END;
$$ LANGUAGE plpgsql;

-- 5.6 칩 히스토리 자동 기록 트리거
CREATE OR REPLACE FUNCTION log_chip_change()
RETURNS TRIGGER AS $$
DECLARE
    v_big_blind INTEGER;
    v_avg_stack INTEGER;
BEGIN
    -- 칩 변동이 있을 때만 기록
    IF OLD.chips IS DISTINCT FROM NEW.chips THEN
        -- 현재 블라인드 조회
        SELECT big_blind INTO v_big_blind
        FROM blind_levels
        WHERE tournament_id = NEW.tournament_id AND is_current = TRUE;

        -- 평균 스택 조회
        SELECT avg_stack INTO v_avg_stack
        FROM tournaments
        WHERE id = NEW.tournament_id;

        INSERT INTO chip_history (
            player_id,
            tournament_id,
            hand_number,
            level_number,
            chips,
            chips_change,
            bb_count,
            avg_stack_percentage,
            source
        )
        SELECT
            NEW.id,
            NEW.tournament_id,
            COALESCE((SELECT MAX(hand_number) FROM hands WHERE tournament_id = NEW.tournament_id), 0),
            COALESCE((SELECT current_level FROM tournaments WHERE id = NEW.tournament_id), 1),
            NEW.chips,
            NEW.chips - COALESCE(OLD.chips, 0),
            calculate_bb_count(NEW.chips, v_big_blind),
            calculate_avg_stack_percentage(NEW.chips, v_avg_stack),
            'auto';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성 (칩 변동 시 자동 기록)
DROP TRIGGER IF EXISTS trg_log_chip_change ON players;
CREATE TRIGGER trg_log_chip_change
    AFTER UPDATE OF chips ON players
    FOR EACH ROW
    EXECUTE FUNCTION log_chip_change();

-- ============================================================
-- 6. GFX Data Import Functions
-- ============================================================

-- 6.1 GFX 세션 임포트 함수
CREATE OR REPLACE FUNCTION import_gfx_session(
    p_gfx_data JSONB,
    p_tournament_id UUID DEFAULT NULL,
    p_feature_table_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_session_id UUID;
BEGIN
    INSERT INTO gfx_sessions (
        tournament_id,
        feature_table_id,
        gfx_id,
        event_title,
        table_type,
        software_version,
        payouts,
        created_at_gfx,
        status
    )
    VALUES (
        p_tournament_id,
        p_feature_table_id,
        (p_gfx_data->>'ID')::BIGINT,
        p_gfx_data->>'EventTitle',
        COALESCE(p_gfx_data->>'Type', 'FEATURE_TABLE'),
        p_gfx_data->>'SoftwareVersion',
        COALESCE(p_gfx_data->'Payouts', '[]'::JSONB),
        (p_gfx_data->>'CreatedDateTimeUTC')::TIMESTAMP,
        'active'
    )
    ON CONFLICT (gfx_id) DO UPDATE SET
        event_title = EXCLUDED.event_title,
        software_version = EXCLUDED.software_version,
        payouts = EXCLUDED.payouts
    RETURNING id INTO v_session_id;

    RETURN v_session_id;
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- ============================================================
-- Rollback Script (if needed)
-- ============================================================
-- DROP FUNCTION IF EXISTS import_gfx_session(JSONB, UUID, UUID);
-- DROP TRIGGER IF EXISTS trg_log_chip_change ON players;
-- DROP FUNCTION IF EXISTS log_chip_change();
-- DROP FUNCTION IF EXISTS update_player_ranks(UUID);
-- DROP FUNCTION IF EXISTS calculate_avg_stack_percentage(INTEGER, INTEGER);
-- DROP FUNCTION IF EXISTS calculate_bb_count(INTEGER, INTEGER);
-- DROP FUNCTION IF EXISTS convert_gfx_hole_cards(JSONB);
-- DROP FUNCTION IF EXISTS convert_gfx_card(TEXT);
-- DROP VIEW IF EXISTS v_l_bar_standard;
-- DROP VIEW IF EXISTS v_current_blind_level;
-- DROP VIEW IF EXISTS v_hand_summary;
-- DROP VIEW IF EXISTS v_vpip_stats;
-- DROP VIEW IF EXISTS v_chip_flow;
-- DROP VIEW IF EXISTS v_recent_eliminations;
-- DROP VIEW IF EXISTS v_at_risk_players;
-- DROP VIEW IF EXISTS v_player_profile;
-- DROP VIEW IF EXISTS v_mini_chip_counts;
-- DROP VIEW IF EXISTS v_feature_table_players;
-- DROP VIEW IF EXISTS v_tournament_leaderboard;
