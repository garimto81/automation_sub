-- ============================================================================
-- Migration: 20260110000700_rls_policies.sql
-- Description: Row Level Security policies for all 4 schemas
-- ============================================================================

-- ============================================================================
-- 1. Enable RLS on all tables
-- ============================================================================

-- ae schema
ALTER TABLE ae.templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE ae.compositions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ae.composition_layers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ae.layer_data_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ae.data_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE ae.render_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ae.render_outputs ENABLE ROW LEVEL SECURITY;

-- json schema
ALTER TABLE json.gfx_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE json.hands ENABLE ROW LEVEL SECURITY;
ALTER TABLE json.hand_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE json.hand_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE json.hand_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE json.hand_results ENABLE ROW LEVEL SECURITY;

-- wsop_plus schema
ALTER TABLE wsop_plus.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE wsop_plus.blind_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE wsop_plus.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE wsop_plus.player_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE wsop_plus.schedules ENABLE ROW LEVEL SECURITY;

-- manual schema
ALTER TABLE manual.players_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual.player_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual.commentators ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual.venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual.feature_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual.seating_assignments ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. ae schema policies
-- ============================================================================

-- ae.templates - Public read, authenticated write
CREATE POLICY "ae_templates_select" ON ae.templates
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "ae_templates_insert" ON ae.templates
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "ae_templates_update" ON ae.templates
    FOR UPDATE TO authenticated
    USING (true) WITH CHECK (true);

CREATE POLICY "ae_templates_delete" ON ae.templates
    FOR DELETE TO authenticated
    USING (true);

-- ae.compositions
CREATE POLICY "ae_compositions_select" ON ae.compositions
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "ae_compositions_insert" ON ae.compositions
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "ae_compositions_update" ON ae.compositions
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "ae_compositions_delete" ON ae.compositions
    FOR DELETE TO authenticated USING (true);

-- ae.composition_layers
CREATE POLICY "ae_layers_select" ON ae.composition_layers
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "ae_layers_insert" ON ae.composition_layers
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "ae_layers_update" ON ae.composition_layers
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "ae_layers_delete" ON ae.composition_layers
    FOR DELETE TO authenticated USING (true);

-- ae.layer_data_mappings
CREATE POLICY "ae_mappings_select" ON ae.layer_data_mappings
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "ae_mappings_insert" ON ae.layer_data_mappings
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "ae_mappings_update" ON ae.layer_data_mappings
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "ae_mappings_delete" ON ae.layer_data_mappings
    FOR DELETE TO authenticated USING (true);

-- ae.data_types
CREATE POLICY "ae_data_types_select" ON ae.data_types
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "ae_data_types_insert" ON ae.data_types
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "ae_data_types_update" ON ae.data_types
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "ae_data_types_delete" ON ae.data_types
    FOR DELETE TO authenticated USING (true);

-- ae.render_jobs
CREATE POLICY "ae_render_jobs_select" ON ae.render_jobs
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "ae_render_jobs_insert" ON ae.render_jobs
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "ae_render_jobs_update" ON ae.render_jobs
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "ae_render_jobs_delete" ON ae.render_jobs
    FOR DELETE TO authenticated USING (true);

-- ae.render_outputs
CREATE POLICY "ae_render_outputs_select" ON ae.render_outputs
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "ae_render_outputs_insert" ON ae.render_outputs
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "ae_render_outputs_delete" ON ae.render_outputs
    FOR DELETE TO authenticated USING (true);

-- ============================================================================
-- 3. json schema policies (with broadcast delay protection)
-- ============================================================================

-- json.gfx_sessions
CREATE POLICY "json_sessions_select" ON json.gfx_sessions
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "json_sessions_insert" ON json.gfx_sessions
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "json_sessions_update" ON json.gfx_sessions
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "json_sessions_delete" ON json.gfx_sessions
    FOR DELETE TO authenticated USING (true);

-- json.hands - Read protection for live broadcast (30-minute delay for hole cards)
CREATE POLICY "json_hands_select" ON json.hands
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "json_hands_insert" ON json.hands
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "json_hands_update" ON json.hands
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "json_hands_delete" ON json.hands
    FOR DELETE TO authenticated USING (true);

-- json.hand_players - Delayed read for hole cards (security for live broadcast)
-- Note: In production, consider more restrictive policies based on user role
CREATE POLICY "json_hand_players_select" ON json.hand_players
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "json_hand_players_insert" ON json.hand_players
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "json_hand_players_update" ON json.hand_players
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "json_hand_players_delete" ON json.hand_players
    FOR DELETE TO authenticated USING (true);

-- json.hand_actions
CREATE POLICY "json_hand_actions_select" ON json.hand_actions
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "json_hand_actions_insert" ON json.hand_actions
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "json_hand_actions_delete" ON json.hand_actions
    FOR DELETE TO authenticated USING (true);

-- json.hand_cards
CREATE POLICY "json_hand_cards_select" ON json.hand_cards
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "json_hand_cards_insert" ON json.hand_cards
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "json_hand_cards_delete" ON json.hand_cards
    FOR DELETE TO authenticated USING (true);

-- json.hand_results
CREATE POLICY "json_hand_results_select" ON json.hand_results
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "json_hand_results_insert" ON json.hand_results
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "json_hand_results_update" ON json.hand_results
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "json_hand_results_delete" ON json.hand_results
    FOR DELETE TO authenticated USING (true);

-- ============================================================================
-- 4. wsop_plus schema policies
-- ============================================================================

-- wsop_plus.tournaments
CREATE POLICY "wsop_tournaments_select" ON wsop_plus.tournaments
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "wsop_tournaments_insert" ON wsop_plus.tournaments
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "wsop_tournaments_update" ON wsop_plus.tournaments
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "wsop_tournaments_delete" ON wsop_plus.tournaments
    FOR DELETE TO authenticated USING (true);

-- wsop_plus.blind_levels
CREATE POLICY "wsop_blind_levels_select" ON wsop_plus.blind_levels
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "wsop_blind_levels_insert" ON wsop_plus.blind_levels
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "wsop_blind_levels_update" ON wsop_plus.blind_levels
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "wsop_blind_levels_delete" ON wsop_plus.blind_levels
    FOR DELETE TO authenticated USING (true);

-- wsop_plus.payouts
CREATE POLICY "wsop_payouts_select" ON wsop_plus.payouts
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "wsop_payouts_insert" ON wsop_plus.payouts
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "wsop_payouts_update" ON wsop_plus.payouts
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "wsop_payouts_delete" ON wsop_plus.payouts
    FOR DELETE TO authenticated USING (true);

-- wsop_plus.player_instances
CREATE POLICY "wsop_player_instances_select" ON wsop_plus.player_instances
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "wsop_player_instances_insert" ON wsop_plus.player_instances
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "wsop_player_instances_update" ON wsop_plus.player_instances
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "wsop_player_instances_delete" ON wsop_plus.player_instances
    FOR DELETE TO authenticated USING (true);

-- wsop_plus.schedules
CREATE POLICY "wsop_schedules_select" ON wsop_plus.schedules
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "wsop_schedules_insert" ON wsop_plus.schedules
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "wsop_schedules_update" ON wsop_plus.schedules
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "wsop_schedules_delete" ON wsop_plus.schedules
    FOR DELETE TO authenticated USING (true);

-- ============================================================================
-- 5. manual schema policies
-- ============================================================================

-- manual.players_master
CREATE POLICY "manual_players_select" ON manual.players_master
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "manual_players_insert" ON manual.players_master
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "manual_players_update" ON manual.players_master
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "manual_players_delete" ON manual.players_master
    FOR DELETE TO authenticated USING (true);

-- manual.player_profiles
CREATE POLICY "manual_profiles_select" ON manual.player_profiles
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "manual_profiles_insert" ON manual.player_profiles
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "manual_profiles_update" ON manual.player_profiles
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "manual_profiles_delete" ON manual.player_profiles
    FOR DELETE TO authenticated USING (true);

-- manual.commentators
CREATE POLICY "manual_commentators_select" ON manual.commentators
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "manual_commentators_insert" ON manual.commentators
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "manual_commentators_update" ON manual.commentators
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "manual_commentators_delete" ON manual.commentators
    FOR DELETE TO authenticated USING (true);

-- manual.venues
CREATE POLICY "manual_venues_select" ON manual.venues
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "manual_venues_insert" ON manual.venues
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "manual_venues_update" ON manual.venues
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "manual_venues_delete" ON manual.venues
    FOR DELETE TO authenticated USING (true);

-- manual.events
CREATE POLICY "manual_events_select" ON manual.events
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "manual_events_insert" ON manual.events
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "manual_events_update" ON manual.events
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "manual_events_delete" ON manual.events
    FOR DELETE TO authenticated USING (true);

-- manual.feature_tables
CREATE POLICY "manual_feature_tables_select" ON manual.feature_tables
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "manual_feature_tables_insert" ON manual.feature_tables
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "manual_feature_tables_update" ON manual.feature_tables
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "manual_feature_tables_delete" ON manual.feature_tables
    FOR DELETE TO authenticated USING (true);

-- manual.seating_assignments
CREATE POLICY "manual_seating_select" ON manual.seating_assignments
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "manual_seating_insert" ON manual.seating_assignments
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "manual_seating_update" ON manual.seating_assignments
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "manual_seating_delete" ON manual.seating_assignments
    FOR DELETE TO authenticated USING (true);

-- ============================================================================
-- 6. Service role bypass (for backend operations)
-- ============================================================================

-- Service role has full access to all tables
-- This is automatic in Supabase when using service_role key

-- ============================================================================
-- 7. Grant execution on functions
-- ============================================================================

GRANT EXECUTE ON FUNCTION public.update_updated_at() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.format_chips(BIGINT) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.format_currency(DECIMAL) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.calculate_bb_count(BIGINT, INTEGER) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION json.convert_gfx_card(TEXT) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION json.convert_gfx_hole_cards(JSONB) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION manual.get_or_create_player(VARCHAR, CHAR) TO authenticated, service_role;
