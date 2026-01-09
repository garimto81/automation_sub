-- ============================================================================
-- Migration: 20260110000500_indexes.sql
-- Description: Strategic indexes for all 4 schemas
-- ============================================================================

-- ============================================================================
-- ae schema indexes
-- ============================================================================

-- ae.templates
CREATE INDEX idx_ae_templates_active ON ae.templates(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_ae_templates_name ON ae.templates(name);
CREATE INDEX idx_ae_templates_updated ON ae.templates(updated_at DESC);

-- ae.compositions
CREATE INDEX idx_ae_compositions_template ON ae.compositions(template_id);
CREATE INDEX idx_ae_compositions_type ON ae.compositions(comp_type);
CREATE INDEX idx_ae_compositions_renderable ON ae.compositions(is_renderable) WHERE is_renderable = TRUE;
CREATE INDEX idx_ae_compositions_name ON ae.compositions(name);

-- ae.composition_layers
CREATE INDEX idx_ae_layers_composition ON ae.composition_layers(composition_id);
CREATE INDEX idx_ae_layers_dynamic ON ae.composition_layers(is_dynamic) WHERE is_dynamic = TRUE;
CREATE INDEX idx_ae_layers_type ON ae.composition_layers(layer_type);
CREATE INDEX idx_ae_layers_slot ON ae.composition_layers(slot_index) WHERE slot_index IS NOT NULL;
CREATE INDEX idx_ae_layers_data_field ON ae.composition_layers(data_field) WHERE data_field IS NOT NULL;

-- ae.layer_data_mappings
CREATE INDEX idx_ae_mappings_layer ON ae.layer_data_mappings(layer_id);
CREATE INDEX idx_ae_mappings_source ON ae.layer_data_mappings(source_schema, source_table);
CREATE INDEX idx_ae_mappings_data_type ON ae.layer_data_mappings(data_type_id);

-- ae.data_types
CREATE INDEX idx_ae_data_types_category ON ae.data_types(category);
CREATE INDEX idx_ae_data_types_active ON ae.data_types(is_active) WHERE is_active = TRUE;

-- ae.render_jobs
CREATE INDEX idx_ae_render_jobs_status ON ae.render_jobs(status);
CREATE INDEX idx_ae_render_jobs_pending ON ae.render_jobs(status, priority DESC, created_at)
    WHERE status = 'pending';
CREATE INDEX idx_ae_render_jobs_composition ON ae.render_jobs(composition_id);
CREATE INDEX idx_ae_render_jobs_created ON ae.render_jobs(created_at DESC);
CREATE INDEX idx_ae_render_jobs_worker ON ae.render_jobs(nexrender_worker)
    WHERE nexrender_worker IS NOT NULL;

-- ae.render_outputs
CREATE INDEX idx_ae_render_outputs_job ON ae.render_outputs(render_job_id);
CREATE INDEX idx_ae_render_outputs_type ON ae.render_outputs(output_type);

-- ============================================================================
-- json schema indexes
-- ============================================================================

-- json.gfx_sessions
CREATE INDEX idx_json_sessions_gfx_id ON json.gfx_sessions(gfx_id);
CREATE INDEX idx_json_sessions_status ON json.gfx_sessions(status);
CREATE INDEX idx_json_sessions_tournament ON json.gfx_sessions(tournament_id)
    WHERE tournament_id IS NOT NULL;
CREATE INDEX idx_json_sessions_feature_table ON json.gfx_sessions(feature_table_id)
    WHERE feature_table_id IS NOT NULL;
CREATE INDEX idx_json_sessions_created ON json.gfx_sessions(created_at DESC);
CREATE INDEX idx_json_sessions_gfx_created ON json.gfx_sessions(created_at_gfx DESC);

-- json.hands
CREATE INDEX idx_json_hands_session ON json.hands(gfx_session_id);
CREATE INDEX idx_json_hands_number ON json.hands(hand_number DESC);
CREATE INDEX idx_json_hands_session_number ON json.hands(gfx_session_id, hand_number DESC);
CREATE INDEX idx_json_hands_grade ON json.hands(grade) WHERE grade IN ('A', 'B');
CREATE INDEX idx_json_hands_premium ON json.hands(is_premium) WHERE is_premium = TRUE;
CREATE INDEX idx_json_hands_showdown ON json.hands(is_showdown) WHERE is_showdown = TRUE;
CREATE INDEX idx_json_hands_winner ON json.hands(winner_player_name) WHERE winner_player_name IS NOT NULL;
CREATE INDEX idx_json_hands_started ON json.hands(started_at DESC);
CREATE INDEX idx_json_hands_level ON json.hands(level_number);

-- json.hand_players
CREATE INDEX idx_json_hand_players_hand ON json.hand_players(hand_id);
CREATE INDEX idx_json_hand_players_seat ON json.hand_players(hand_id, seat_number);
CREATE INDEX idx_json_hand_players_name ON json.hand_players(player_name);
CREATE INDEX idx_json_hand_players_winner ON json.hand_players(is_winner) WHERE is_winner = TRUE;
CREATE INDEX idx_json_hand_players_master ON json.hand_players(player_master_id)
    WHERE player_master_id IS NOT NULL;
CREATE INDEX idx_json_hand_players_eliminated ON json.hand_players(is_eliminated) WHERE is_eliminated = TRUE;
CREATE INDEX idx_json_hand_players_stack_delta ON json.hand_players(stack_delta DESC);

-- json.hand_actions
CREATE INDEX idx_json_hand_actions_hand ON json.hand_actions(hand_id);
CREATE INDEX idx_json_hand_actions_order ON json.hand_actions(hand_id, action_order);
CREATE INDEX idx_json_hand_actions_street ON json.hand_actions(hand_id, street);
CREATE INDEX idx_json_hand_actions_type ON json.hand_actions(event_type);
CREATE INDEX idx_json_hand_actions_action ON json.hand_actions(action);
CREATE INDEX idx_json_hand_actions_player ON json.hand_actions(player_name)
    WHERE player_name IS NOT NULL;

-- json.hand_cards
CREATE INDEX idx_json_hand_cards_hand ON json.hand_cards(hand_id);
CREATE INDEX idx_json_hand_cards_type ON json.hand_cards(hand_id, card_type);
CREATE INDEX idx_json_hand_cards_seat ON json.hand_cards(hand_id, seat_number)
    WHERE seat_number IS NOT NULL;
CREATE INDEX idx_json_hand_cards_board ON json.hand_cards(hand_id, board_num);

-- json.hand_results
CREATE INDEX idx_json_hand_results_hand ON json.hand_results(hand_id);
CREATE INDEX idx_json_hand_results_winner ON json.hand_results(is_winner) WHERE is_winner = TRUE;
CREATE INDEX idx_json_hand_results_seat ON json.hand_results(hand_id, seat_number);
CREATE INDEX idx_json_hand_results_rank ON json.hand_results(rank_value) WHERE rank_value IS NOT NULL;

-- ============================================================================
-- wsop_plus schema indexes
-- ============================================================================

-- wsop_plus.tournaments
CREATE INDEX idx_wsop_tournaments_status ON wsop_plus.tournaments(status);
CREATE INDEX idx_wsop_tournaments_event ON wsop_plus.tournaments(event_id)
    WHERE event_id IS NOT NULL;
CREATE INDEX idx_wsop_tournaments_venue ON wsop_plus.tournaments(venue_id)
    WHERE venue_id IS NOT NULL;
CREATE INDEX idx_wsop_tournaments_scheduled ON wsop_plus.tournaments(scheduled_start DESC);
CREATE INDEX idx_wsop_tournaments_running ON wsop_plus.tournaments(status)
    WHERE status IN ('running', 'final_table');
CREATE INDEX idx_wsop_tournaments_code ON wsop_plus.tournaments(tournament_code)
    WHERE tournament_code IS NOT NULL;

-- wsop_plus.blind_levels
CREATE INDEX idx_wsop_blind_levels_tournament ON wsop_plus.blind_levels(tournament_id);
CREATE INDEX idx_wsop_blind_levels_current ON wsop_plus.blind_levels(is_current)
    WHERE is_current = TRUE;
CREATE INDEX idx_wsop_blind_levels_level ON wsop_plus.blind_levels(tournament_id, level_number);
CREATE INDEX idx_wsop_blind_levels_break ON wsop_plus.blind_levels(is_break) WHERE is_break = TRUE;

-- wsop_plus.payouts
CREATE INDEX idx_wsop_payouts_tournament ON wsop_plus.payouts(tournament_id);
CREATE INDEX idx_wsop_payouts_bubble ON wsop_plus.payouts(is_current_bubble)
    WHERE is_current_bubble = TRUE;
CREATE INDEX idx_wsop_payouts_place ON wsop_plus.payouts(tournament_id, place_start);
CREATE INDEX idx_wsop_payouts_amount ON wsop_plus.payouts(amount DESC);

-- wsop_plus.player_instances
CREATE INDEX idx_wsop_player_instances_tournament ON wsop_plus.player_instances(tournament_id);
CREATE INDEX idx_wsop_player_instances_chips ON wsop_plus.player_instances(chips DESC);
CREATE INDEX idx_wsop_player_instances_rank ON wsop_plus.player_instances(current_rank);
CREATE INDEX idx_wsop_player_instances_name ON wsop_plus.player_instances(player_name);
CREATE INDEX idx_wsop_player_instances_active ON wsop_plus.player_instances(tournament_id, chips DESC)
    WHERE is_eliminated = FALSE;
CREATE INDEX idx_wsop_player_instances_eliminated ON wsop_plus.player_instances(is_eliminated)
    WHERE is_eliminated = TRUE;
CREATE INDEX idx_wsop_player_instances_feature ON wsop_plus.player_instances(is_feature_table)
    WHERE is_feature_table = TRUE;
CREATE INDEX idx_wsop_player_instances_master ON wsop_plus.player_instances(player_master_id)
    WHERE player_master_id IS NOT NULL;

-- wsop_plus.schedules
CREATE INDEX idx_wsop_schedules_date ON wsop_plus.schedules(date);
CREATE INDEX idx_wsop_schedules_live ON wsop_plus.schedules(is_live) WHERE is_live = TRUE;
CREATE INDEX idx_wsop_schedules_tournament ON wsop_plus.schedules(tournament_id)
    WHERE tournament_id IS NOT NULL;
CREATE INDEX idx_wsop_schedules_event ON wsop_plus.schedules(event_id)
    WHERE event_id IS NOT NULL;
CREATE INDEX idx_wsop_schedules_start ON wsop_plus.schedules(start_timestamp DESC);

-- ============================================================================
-- manual schema indexes
-- ============================================================================

-- manual.players_master
CREATE INDEX idx_manual_players_name ON manual.players_master(name);
CREATE INDEX idx_manual_players_display_name ON manual.players_master(display_name)
    WHERE display_name IS NOT NULL;
CREATE INDEX idx_manual_players_nationality ON manual.players_master(nationality);
CREATE INDEX idx_manual_players_key ON manual.players_master(is_key_player)
    WHERE is_key_player = TRUE;
CREATE INDEX idx_manual_players_active ON manual.players_master(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_manual_players_bracelets ON manual.players_master(wsop_bracelets DESC)
    WHERE wsop_bracelets > 0;
CREATE INDEX idx_manual_players_earnings ON manual.players_master(total_earnings DESC);
CREATE INDEX idx_manual_players_hendon ON manual.players_master(hendon_mob_id)
    WHERE hendon_mob_id IS NOT NULL;
CREATE INDEX idx_manual_players_search ON manual.players_master
    USING gin (to_tsvector('simple', COALESCE(name, '') || ' ' || COALESCE(display_name, '')));

-- manual.player_profiles
CREATE INDEX idx_manual_profiles_player ON manual.player_profiles(player_id);
CREATE INDEX idx_manual_profiles_style ON manual.player_profiles(playing_style)
    WHERE playing_style IS NOT NULL;

-- manual.commentators
CREATE INDEX idx_manual_commentators_name ON manual.commentators(name);
CREATE INDEX idx_manual_commentators_active ON manual.commentators(is_active)
    WHERE is_active = TRUE;
CREATE INDEX idx_manual_commentators_primary ON manual.commentators(is_primary)
    WHERE is_primary = TRUE;
CREATE INDEX idx_manual_commentators_player ON manual.commentators(player_id)
    WHERE player_id IS NOT NULL;

-- manual.venues
CREATE INDEX idx_manual_venues_name ON manual.venues(name);
CREATE INDEX idx_manual_venues_city ON manual.venues(city);
CREATE INDEX idx_manual_venues_country ON manual.venues(country);
CREATE INDEX idx_manual_venues_active ON manual.venues(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_manual_venues_location ON manual.venues(latitude, longitude)
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- manual.events
CREATE INDEX idx_manual_events_code ON manual.events(event_code);
CREATE INDEX idx_manual_events_venue ON manual.events(venue_id) WHERE venue_id IS NOT NULL;
CREATE INDEX idx_manual_events_dates ON manual.events(start_date, end_date);
CREATE INDEX idx_manual_events_status ON manual.events(status);
CREATE INDEX idx_manual_events_series ON manual.events(series_code) WHERE series_code IS NOT NULL;
CREATE INDEX idx_manual_events_active ON manual.events(status)
    WHERE status IN ('scheduled', 'upcoming', 'active');

-- manual.feature_tables
CREATE INDEX idx_manual_feature_tables_tournament ON manual.feature_tables(tournament_id)
    WHERE tournament_id IS NOT NULL;
CREATE INDEX idx_manual_feature_tables_active ON manual.feature_tables(is_active)
    WHERE is_active = TRUE;
CREATE INDEX idx_manual_feature_tables_streaming ON manual.feature_tables(is_streaming)
    WHERE is_streaming = TRUE;
CREATE INDEX idx_manual_feature_tables_main ON manual.feature_tables(is_main_feature)
    WHERE is_main_feature = TRUE;
CREATE INDEX idx_manual_feature_tables_rfid ON manual.feature_tables(rfid_device_id)
    WHERE rfid_device_id IS NOT NULL;

-- manual.seating_assignments
CREATE INDEX idx_manual_seating_table ON manual.seating_assignments(feature_table_id);
CREATE INDEX idx_manual_seating_player ON manual.seating_assignments(player_id);
CREATE INDEX idx_manual_seating_current ON manual.seating_assignments(feature_table_id, is_current)
    WHERE is_current = TRUE;
CREATE INDEX idx_manual_seating_seat ON manual.seating_assignments(feature_table_id, seat_number);
CREATE INDEX idx_manual_seating_assigned ON manual.seating_assignments(assigned_at DESC);
