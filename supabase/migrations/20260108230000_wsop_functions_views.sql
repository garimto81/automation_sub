-- ============================================================
-- Migration: 20260108230000_wsop_functions_views.sql
-- Description: WSOP 스키마 함수 및 뷰
-- Author: Claude Code
-- Date: 2026-01-08
-- ============================================================

SET search_path TO wsop, public;

-- ============================================================
-- Functions
-- ============================================================

-- 카드 형식 변환 (pokerGFX -> DB)
CREATE OR REPLACE FUNCTION wsop.convert_gfx_card(gfx_card TEXT)
RETURNS VARCHAR(2) AS $$
DECLARE
    rank_part TEXT;
    suit_part CHAR(1);
BEGIN
    IF gfx_card IS NULL OR LENGTH(gfx_card) < 2 THEN
        RETURN NULL;
    END IF;

    rank_part := UPPER(LEFT(gfx_card, LENGTH(gfx_card) - 1));
    suit_part := LOWER(RIGHT(gfx_card, 1));

    IF rank_part = '10' THEN
        rank_part := 'T';
    END IF;

    RETURN rank_part || suit_part;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 홀카드 배열 변환
CREATE OR REPLACE FUNCTION wsop.convert_gfx_hole_cards(gfx_cards JSONB)
RETURNS VARCHAR(10) AS $$
DECLARE
    card1 TEXT;
    card2 TEXT;
BEGIN
    IF gfx_cards IS NULL OR jsonb_array_length(gfx_cards) < 2 THEN
        RETURN NULL;
    END IF;

    card1 := wsop.convert_gfx_card(gfx_cards->>0);
    card2 := wsop.convert_gfx_card(gfx_cards->>1);

    RETURN card1 || card2;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 플레이어 마스터 조회 또는 생성
CREATE OR REPLACE FUNCTION wsop.get_or_create_player_master(
    p_name VARCHAR(255),
    p_nationality CHAR(2) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_player_id UUID;
BEGIN
    SELECT id INTO v_player_id
    FROM wsop.players_master
    WHERE name = p_name AND (nationality = p_nationality OR (nationality IS NULL AND p_nationality IS NULL));

    IF v_player_id IS NULL THEN
        INSERT INTO wsop.players_master (name, nationality)
        VALUES (p_name, p_nationality)
        RETURNING id INTO v_player_id;
    END IF;

    RETURN v_player_id;
END;
$$ LANGUAGE plpgsql;

-- 토너먼트 순위 업데이트
CREATE OR REPLACE FUNCTION wsop.update_tournament_ranks(p_tournament_id UUID)
RETURNS VOID AS $$
BEGIN
    WITH ranked AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY chips DESC) as new_rank
        FROM wsop.player_instances
        WHERE tournament_id = p_tournament_id AND NOT is_eliminated
    )
    UPDATE wsop.player_instances pi
    SET current_rank = r.new_rank, updated_at = NOW()
    FROM ranked r
    WHERE pi.id = r.id;

    UPDATE wsop.tournaments
    SET remaining_players = (
        SELECT COUNT(*) FROM wsop.player_instances
        WHERE tournament_id = p_tournament_id AND NOT is_eliminated
    ),
    avg_stack = (
        SELECT AVG(chips)::INTEGER FROM wsop.player_instances
        WHERE tournament_id = p_tournament_id AND NOT is_eliminated
    ),
    updated_at = NOW()
    WHERE id = p_tournament_id;
END;
$$ LANGUAGE plpgsql;

-- updated_at 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION wsop.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Views
-- ============================================================

-- 토너먼트 리더보드
CREATE OR REPLACE VIEW wsop.v_tournament_leaderboard AS
SELECT
    pi.tournament_id,
    t.name AS tournament_name,
    pi.current_rank,
    pm.name AS player_name,
    pm.nationality,
    pm.photo_url,
    pi.chips,
    ROUND(pi.chips::DECIMAL / bl.big_blind, 1) AS bb_count,
    pi.seat_number,
    pi.is_feature_table,
    ps.vpip,
    ps.pfr,
    ps.aggression_factor
FROM wsop.player_instances pi
JOIN wsop.players_master pm ON pi.player_id = pm.id
JOIN wsop.tournaments t ON pi.tournament_id = t.id
LEFT JOIN wsop.player_stats ps ON pi.id = ps.player_instance_id
LEFT JOIN wsop.blind_levels bl ON t.id = bl.tournament_id AND bl.is_current = TRUE
WHERE NOT pi.is_eliminated
ORDER BY pi.current_rank;

-- 피처 테이블 플레이어
CREATE OR REPLACE VIEW wsop.v_feature_table_players AS
SELECT
    pi.tournament_id,
    ft.table_number,
    ft.table_name,
    pi.seat_number,
    pm.name AS player_name,
    pm.nationality,
    pm.photo_url,
    pm.bracelets,
    pi.chips,
    pi.current_rank,
    ps.vpip,
    ps.pfr,
    ps.hands_played,
    cf.chip_change AS last_change
FROM wsop.player_instances pi
JOIN wsop.players_master pm ON pi.player_id = pm.id
JOIN wsop.feature_tables ft ON pi.feature_table_id = ft.id
LEFT JOIN wsop.player_stats ps ON pi.id = ps.player_instance_id
LEFT JOIN LATERAL (
    SELECT chip_change FROM wsop.chip_flow
    WHERE player_instance_id = pi.id
    ORDER BY recorded_at DESC LIMIT 1
) cf ON TRUE
WHERE pi.is_feature_table = TRUE AND NOT pi.is_eliminated
ORDER BY ft.table_number, pi.seat_number;

-- 프리미엄 핸드
CREATE OR REPLACE VIEW wsop.v_premium_hands AS
SELECT
    h.id AS hand_id,
    h.hand_number,
    t.name AS tournament_name,
    gs.event_title,
    h.started_at,
    h.final_pot,
    h.duration,
    pm.name AS winner_name,
    (SELECT string_agg(
        pm2.name || ': ' || hp.hole_cards, ', '
    ) FROM wsop.hand_players hp
    JOIN wsop.player_instances pi2 ON hp.player_instance_id = pi2.id
    JOIN wsop.players_master pm2 ON pi2.player_id = pm2.id
    WHERE hp.hand_id = h.id AND hp.hole_cards IS NOT NULL
    ) AS showdown_hands
FROM wsop.hands h
JOIN wsop.gfx_sessions gs ON h.gfx_session_id = gs.id
JOIN wsop.tournaments t ON h.tournament_id = t.id
LEFT JOIN wsop.player_instances wi ON h.winner_id = wi.id
LEFT JOIN wsop.players_master pm ON wi.player_id = pm.id
WHERE h.is_premium = TRUE
ORDER BY h.started_at DESC;

-- 탈락 히스토리
CREATE OR REPLACE VIEW wsop.v_eliminations AS
SELECT
    e.id,
    t.name AS tournament_name,
    pm.name AS player_name,
    pm.nationality,
    e.final_rank,
    e.payout_received,
    em.name AS eliminator_name,
    e.player_hole_cards,
    e.eliminator_hole_cards,
    e.board_cards,
    e.eliminated_at
FROM wsop.eliminations e
JOIN wsop.player_instances pi ON e.player_instance_id = pi.id
JOIN wsop.players_master pm ON pi.player_id = pm.id
JOIN wsop.tournaments t ON pi.tournament_id = t.id
LEFT JOIN wsop.player_instances ei ON e.eliminator_id = ei.id
LEFT JOIN wsop.players_master em ON ei.player_id = em.id
ORDER BY e.eliminated_at DESC;

-- 칩 플로우 요약
CREATE OR REPLACE VIEW wsop.v_chip_flow_summary AS
SELECT
    cf.player_instance_id,
    pm.name AS player_name,
    t.name AS tournament_name,
    COUNT(*) AS total_changes,
    SUM(CASE WHEN chip_change > 0 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN chip_change < 0 THEN 1 ELSE 0 END) AS losses,
    MAX(chips_after) AS peak_chips,
    MIN(chips_after) AS lowest_chips,
    SUM(chip_change) AS net_change
FROM wsop.chip_flow cf
JOIN wsop.player_instances pi ON cf.player_instance_id = pi.id
JOIN wsop.players_master pm ON pi.player_id = pm.id
JOIN wsop.tournaments t ON pi.tournament_id = t.id
GROUP BY cf.player_instance_id, pm.name, t.name;

-- 그래픽 큐 현황
CREATE OR REPLACE VIEW wsop.v_graphics_pending AS
SELECT
    gq.id,
    gq.graphic_type,
    gq.trigger_event,
    gq.priority,
    gq.status,
    t.name AS tournament_name,
    gq.scheduled_at,
    gq.created_at,
    gq.payload
FROM wsop.graphics_queue gq
JOIN wsop.tournaments t ON gq.tournament_id = t.id
WHERE gq.status IN ('pending', 'scheduled')
ORDER BY gq.priority DESC, gq.created_at;

-- ============================================================
-- Triggers
-- ============================================================

-- updated_at 트리거 적용
CREATE TRIGGER tr_venues_updated_at BEFORE UPDATE ON wsop.venues
    FOR EACH ROW EXECUTE FUNCTION wsop.update_updated_at();

CREATE TRIGGER tr_events_updated_at BEFORE UPDATE ON wsop.events
    FOR EACH ROW EXECUTE FUNCTION wsop.update_updated_at();

CREATE TRIGGER tr_tournaments_updated_at BEFORE UPDATE ON wsop.tournaments
    FOR EACH ROW EXECUTE FUNCTION wsop.update_updated_at();

CREATE TRIGGER tr_players_master_updated_at BEFORE UPDATE ON wsop.players_master
    FOR EACH ROW EXECUTE FUNCTION wsop.update_updated_at();

CREATE TRIGGER tr_player_instances_updated_at BEFORE UPDATE ON wsop.player_instances
    FOR EACH ROW EXECUTE FUNCTION wsop.update_updated_at();

CREATE TRIGGER tr_feature_tables_updated_at BEFORE UPDATE ON wsop.feature_tables
    FOR EACH ROW EXECUTE FUNCTION wsop.update_updated_at();

CREATE TRIGGER tr_gfx_sessions_updated_at BEFORE UPDATE ON wsop.gfx_sessions
    FOR EACH ROW EXECUTE FUNCTION wsop.update_updated_at();

CREATE TRIGGER tr_commentators_updated_at BEFORE UPDATE ON wsop.commentators
    FOR EACH ROW EXECUTE FUNCTION wsop.update_updated_at();

RESET search_path;
