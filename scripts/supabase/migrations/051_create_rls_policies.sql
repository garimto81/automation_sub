-- ============================================================
-- Migration: 051_create_rls_policies.sql
-- Description: Supabase 통합 스키마 - RLS 정책
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 6 - RLS & Realtime
-- ============================================================

-- ============================================================
-- 1. Public Read Policies (모든 인증 사용자 읽기 가능)
-- ============================================================

-- Venues
CREATE POLICY "public_read_venues" ON venues
    FOR SELECT TO authenticated
    USING (true);

-- Events
CREATE POLICY "public_read_events" ON events
    FOR SELECT TO authenticated
    USING (true);

-- Tournaments
CREATE POLICY "public_read_tournaments" ON tournaments
    FOR SELECT TO authenticated
    USING (true);

-- Blind Levels
CREATE POLICY "public_read_blind_levels" ON blind_levels
    FOR SELECT TO authenticated
    USING (true);

-- Payouts
CREATE POLICY "public_read_payouts" ON payouts
    FOR SELECT TO authenticated
    USING (true);

-- Commentators
CREATE POLICY "public_read_commentators" ON commentators
    FOR SELECT TO authenticated
    USING (true);

-- Schedules
CREATE POLICY "public_read_schedules" ON schedules
    FOR SELECT TO authenticated
    USING (true);

-- Players Master
CREATE POLICY "public_read_players_master" ON players_master
    FOR SELECT TO authenticated
    USING (true);

-- Player Instances
CREATE POLICY "public_read_player_instances" ON player_instances
    FOR SELECT TO authenticated
    USING (true);

-- Player Stats
CREATE POLICY "public_read_player_stats" ON player_stats
    FOR SELECT TO authenticated
    USING (true);

-- Feature Tables
CREATE POLICY "public_read_feature_tables" ON feature_tables
    FOR SELECT TO authenticated
    USING (true);

-- GFX Sessions
CREATE POLICY "public_read_gfx_sessions" ON gfx_sessions
    FOR SELECT TO authenticated
    USING (true);

-- Eliminations
CREATE POLICY "public_read_eliminations" ON eliminations
    FOR SELECT TO authenticated
    USING (true);

-- Soft Contents
CREATE POLICY "public_read_soft_contents" ON soft_contents
    FOR SELECT TO authenticated
    USING (true);

-- ============================================================
-- 2. Delayed Read Policies (30분 딜레이)
-- ============================================================

-- Hands (완료 후 30분 지연 또는 방송팀만)
CREATE POLICY "delayed_read_hands" ON hands
    FOR SELECT TO authenticated
    USING (
        completed_at IS NULL
        OR completed_at < NOW() - INTERVAL '30 minutes'
        OR (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role')
    );

-- Hand Players (핸드와 동일 정책)
CREATE POLICY "delayed_read_hand_players" ON hand_players
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM hands h
            WHERE h.id = hand_players.hand_id
            AND (
                h.completed_at IS NULL
                OR h.completed_at < NOW() - INTERVAL '30 minutes'
                OR (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role')
            )
        )
    );

-- Hand Actions (핸드와 동일 정책)
CREATE POLICY "delayed_read_hand_actions" ON hand_actions
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM hands h
            WHERE h.id = hand_actions.hand_id
            AND (
                h.completed_at IS NULL
                OR h.completed_at < NOW() - INTERVAL '30 minutes'
                OR (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role')
            )
        )
    );

-- Hand Cards (핸드와 동일 정책)
CREATE POLICY "delayed_read_hand_cards" ON hand_cards
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM hands h
            WHERE h.id = hand_cards.hand_id
            AND (
                h.completed_at IS NULL
                OR h.completed_at < NOW() - INTERVAL '30 minutes'
                OR (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role')
            )
        )
    );

-- Chip Flow
CREATE POLICY "public_read_chip_flow" ON chip_flow
    FOR SELECT TO authenticated
    USING (true);

-- ============================================================
-- 3. Broadcaster Only Policies (방송팀 전용)
-- ============================================================

-- Graphics Queue (방송팀만)
CREATE POLICY "broadcaster_read_graphics_queue" ON graphics_queue
    FOR SELECT TO authenticated
    USING (
        (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role')
    );

-- Clip Markers (방송팀만)
CREATE POLICY "broadcaster_read_clip_markers" ON clip_markers
    FOR SELECT TO authenticated
    USING (
        (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role')
    );

-- AI Results (방송팀만)
CREATE POLICY "broadcaster_read_ai_results" ON ai_results
    FOR SELECT TO authenticated
    USING (
        (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role')
    );

-- ============================================================
-- 4. Admin Write Policies (관리자만 쓰기)
-- ============================================================

-- 모든 테이블에 admin/service_role 쓰기 권한
CREATE POLICY "admin_write_venues" ON venues
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_events" ON events
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_tournaments" ON tournaments
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_blind_levels" ON blind_levels
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_payouts" ON payouts
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_commentators" ON commentators
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_schedules" ON schedules
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_players_master" ON players_master
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_player_instances" ON player_instances
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_player_stats" ON player_stats
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_feature_tables" ON feature_tables
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_gfx_sessions" ON gfx_sessions
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_hands" ON hands
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_hand_players" ON hand_players
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_hand_actions" ON hand_actions
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_hand_cards" ON hand_cards
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_chip_flow" ON chip_flow
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_graphics_queue" ON graphics_queue
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role', 'broadcaster'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role', 'broadcaster'));

CREATE POLICY "admin_write_eliminations" ON eliminations
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

CREATE POLICY "admin_write_soft_contents" ON soft_contents
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role', 'broadcaster'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role', 'broadcaster'));

CREATE POLICY "admin_write_clip_markers" ON clip_markers
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role', 'broadcaster'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role', 'broadcaster'));

CREATE POLICY "admin_write_ai_results" ON ai_results
    FOR ALL TO authenticated
    USING ((auth.jwt() ->> 'role') IN ('admin', 'service_role'))
    WITH CHECK ((auth.jwt() ->> 'role') IN ('admin', 'service_role'));

-- Comment
COMMENT ON POLICY "delayed_read_hands" ON hands IS '핸드 데이터 30분 딜레이 (방송 보호)';
