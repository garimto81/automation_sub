-- ============================================================
-- Migration: 040_create_views.sql
-- Description: Supabase 통합 스키마 - Views
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 5 - Views & Functions
-- ============================================================

-- ============================================================
-- 1. Tournament Views
-- ============================================================

-- v_tournament_leaderboard - 토너먼트 리더보드
CREATE OR REPLACE VIEW v_tournament_leaderboard AS
SELECT
    pi.id AS player_instance_id,
    pm.id AS player_id,
    pm.name,
    pm.display_name,
    pm.nationality,
    pm.photo_url,
    pm.wsop_bracelets,
    pi.tournament_id,
    pi.chips,
    pi.current_rank,
    pi.rank_change,
    pi.bb_count,
    pi.avg_stack_percentage,
    pi.is_eliminated,
    pi.final_rank,
    pi.payout_received,
    ps.vpip,
    ps.pfr,
    ps.hands_played
FROM player_instances pi
JOIN players_master pm ON pi.player_id = pm.id
LEFT JOIN player_stats ps ON pi.id = ps.player_instance_id
WHERE pi.is_eliminated = FALSE
ORDER BY pi.chips DESC;

-- v_feature_table_players - 피처 테이블 플레이어
CREATE OR REPLACE VIEW v_feature_table_players AS
SELECT
    pi.id AS player_instance_id,
    pm.id AS player_id,
    pm.name,
    pm.display_name,
    pm.nationality,
    pm.photo_url,
    pi.tournament_id,
    pi.chips,
    pi.seat_number,
    pi.table_number,
    pi.current_rank,
    ft.id AS feature_table_id,
    ft.table_name,
    ft.is_streaming,
    ps.vpip,
    ps.pfr,
    ps.aggression_factor
FROM player_instances pi
JOIN players_master pm ON pi.player_id = pm.id
JOIN feature_tables ft ON pi.feature_table_id = ft.id
LEFT JOIN player_stats ps ON pi.id = ps.player_instance_id
WHERE pi.is_eliminated = FALSE
  AND ft.is_active = TRUE
ORDER BY pi.seat_number;

-- v_elimination_summary - 탈락 요약
CREATE OR REPLACE VIEW v_elimination_summary AS
SELECT
    e.id AS elimination_id,
    pm.name AS player_name,
    pm.display_name,
    pm.nationality,
    pm.photo_url,
    e.final_rank,
    e.payout_received,
    e.final_hand,
    e.losing_hand,
    pm_winner.name AS eliminated_by_name,
    e.eliminated_at,
    t.name AS tournament_name
FROM eliminations e
JOIN player_instances pi ON e.player_instance_id = pi.id
JOIN players_master pm ON pi.player_id = pm.id
JOIN tournaments t ON e.tournament_id = t.id
LEFT JOIN players_master pm_winner ON e.eliminated_by_id = pm_winner.id
ORDER BY e.eliminated_at DESC;

-- ============================================================
-- 2. Hand Views
-- ============================================================

-- v_hand_summary - 핸드 요약
CREATE OR REPLACE VIEW v_hand_summary AS
SELECT
    h.id AS hand_id,
    h.hand_number,
    h.game_variant,
    h.pot_size,
    h.grade,
    h.is_premium,
    h.started_at,
    h.completed_at,
    pm.name AS winner_name,
    h.winning_hand,
    gs.table_type,
    t.name AS tournament_name
FROM hands h
LEFT JOIN players_master pm ON h.winner_id = pm.id
LEFT JOIN gfx_sessions gs ON h.gfx_session_id = gs.id
LEFT JOIN tournaments t ON h.tournament_id = t.id
ORDER BY h.started_at DESC;

-- v_premium_hands - 프리미엄 핸드 (Grade A/B)
CREATE OR REPLACE VIEW v_premium_hands AS
SELECT
    h.id AS hand_id,
    h.hand_number,
    h.pot_size,
    h.grade,
    h.grade_factors,
    h.winning_hand,
    pm.name AS winner_name,
    h.started_at,
    cm.marker_type,
    cm.start_timecode,
    cm.end_timecode
FROM hands h
LEFT JOIN players_master pm ON h.winner_id = pm.id
LEFT JOIN clip_markers cm ON h.id = cm.hand_id
WHERE h.grade IN ('A', 'B')
ORDER BY h.started_at DESC;

-- ============================================================
-- 3. Chip Flow Views
-- ============================================================

-- v_chip_flow_timeline - 칩 플로우 타임라인
CREATE OR REPLACE VIEW v_chip_flow_timeline AS
SELECT
    cf.id AS chip_flow_id,
    pm.name AS player_name,
    pm.display_name,
    cf.delta,
    cf.reason,
    cf.running_total,
    cf.hand_number,
    cf.level_number,
    cf.bb_count,
    cf.timestamp,
    t.name AS tournament_name
FROM chip_flow cf
JOIN player_instances pi ON cf.player_instance_id = pi.id
JOIN players_master pm ON pi.player_id = pm.id
JOIN tournaments t ON pi.tournament_id = t.id
ORDER BY cf.timestamp DESC;

-- ============================================================
-- 4. Graphics Queue Views
-- ============================================================

-- v_pending_graphics - 대기 중인 그래픽
CREATE OR REPLACE VIEW v_pending_graphics AS
SELECT
    gq.id AS queue_id,
    gq.graphic_type,
    gq.trigger_event,
    gq.priority,
    gq.payload,
    gq.created_at,
    gq.scheduled_at,
    t.name AS tournament_name
FROM graphics_queue gq
LEFT JOIN tournaments t ON gq.tournament_id = t.id
WHERE gq.status = 'pending'
ORDER BY gq.priority ASC, gq.created_at ASC;

-- Comment
COMMENT ON VIEW v_tournament_leaderboard IS '토너먼트 리더보드 (활성 플레이어만)';
COMMENT ON VIEW v_feature_table_players IS '피처 테이블 플레이어 (좌석순 정렬)';
COMMENT ON VIEW v_premium_hands IS '프리미엄 핸드 (Grade A/B)';
