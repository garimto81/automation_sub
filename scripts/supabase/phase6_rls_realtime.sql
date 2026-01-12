-- ============================================================
-- Phase 6: RLS & Realtime
-- Supabase SQL Editor에서 실행
-- ============================================================

-- ============================================================
-- Enable Row Level Security
-- ============================================================

ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE blind_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE commentators ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE players_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE hands ENABLE ROW LEVEL SECURITY;
ALTER TABLE hand_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE hand_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE hand_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE chip_flow ENABLE ROW LEVEL SECURITY;
ALTER TABLE graphics_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE eliminations ENABLE ROW LEVEL SECURITY;
ALTER TABLE soft_contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE clip_markers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_results ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Public Read Policies
-- ============================================================

CREATE POLICY "public_read_venues" ON venues FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_events" ON events FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_tournaments" ON tournaments FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_blind_levels" ON blind_levels FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_payouts" ON payouts FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_commentators" ON commentators FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_schedules" ON schedules FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_players_master" ON players_master FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_player_instances" ON player_instances FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_player_stats" ON player_stats FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_feature_tables" ON feature_tables FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_gfx_sessions" ON gfx_sessions FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_eliminations" ON eliminations FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_soft_contents" ON soft_contents FOR SELECT TO authenticated USING (true);
CREATE POLICY "public_read_chip_flow" ON chip_flow FOR SELECT TO authenticated USING (true);

-- Delayed read for hands (30분 딜레이)
CREATE POLICY "delayed_read_hands" ON hands FOR SELECT TO authenticated
USING (
    completed_at IS NULL
    OR completed_at < NOW() - INTERVAL '30 minutes'
    OR (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role')
);

CREATE POLICY "delayed_read_hand_players" ON hand_players FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM hands h WHERE h.id = hand_players.hand_id
        AND (h.completed_at IS NULL OR h.completed_at < NOW() - INTERVAL '30 minutes'
        OR (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role'))
    )
);

CREATE POLICY "delayed_read_hand_actions" ON hand_actions FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM hands h WHERE h.id = hand_actions.hand_id
        AND (h.completed_at IS NULL OR h.completed_at < NOW() - INTERVAL '30 minutes'
        OR (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role'))
    )
);

CREATE POLICY "delayed_read_hand_cards" ON hand_cards FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM hands h WHERE h.id = hand_cards.hand_id
        AND (h.completed_at IS NULL OR h.completed_at < NOW() - INTERVAL '30 minutes'
        OR (auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role'))
    )
);

-- Broadcaster only
CREATE POLICY "broadcaster_read_graphics_queue" ON graphics_queue FOR SELECT TO authenticated
USING ((auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role'));

CREATE POLICY "broadcaster_read_clip_markers" ON clip_markers FOR SELECT TO authenticated
USING ((auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role'));

CREATE POLICY "broadcaster_read_ai_results" ON ai_results FOR SELECT TO authenticated
USING ((auth.jwt() ->> 'role') IN ('admin', 'broadcaster', 'service_role'));

-- ============================================================
-- Service Role Write Policies (API용)
-- ============================================================

CREATE POLICY "service_write_all" ON venues FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_events" ON events FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_tournaments" ON tournaments FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_blind_levels" ON blind_levels FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_payouts" ON payouts FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_commentators" ON commentators FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_schedules" ON schedules FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_players_master" ON players_master FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_player_instances" ON player_instances FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_player_stats" ON player_stats FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_feature_tables" ON feature_tables FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_gfx_sessions" ON gfx_sessions FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_hands" ON hands FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_hand_players" ON hand_players FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_hand_actions" ON hand_actions FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_hand_cards" ON hand_cards FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_chip_flow" ON chip_flow FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_graphics_queue" ON graphics_queue FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_eliminations" ON eliminations FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_soft_contents" ON soft_contents FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_clip_markers" ON clip_markers FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_write_ai_results" ON ai_results FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================
-- Enable Realtime
-- ============================================================

-- P0: 필수 실시간 테이블
ALTER PUBLICATION supabase_realtime ADD TABLE hands;
ALTER PUBLICATION supabase_realtime ADD TABLE player_instances;
ALTER PUBLICATION supabase_realtime ADD TABLE graphics_queue;
ALTER PUBLICATION supabase_realtime ADD TABLE blind_levels;

-- P1: 권장 실시간 테이블
ALTER PUBLICATION supabase_realtime ADD TABLE chip_flow;
ALTER PUBLICATION supabase_realtime ADD TABLE eliminations;
ALTER PUBLICATION supabase_realtime ADD TABLE feature_tables;
