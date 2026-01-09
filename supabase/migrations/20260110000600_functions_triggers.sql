-- ============================================================================
-- Migration: 20260110000600_functions_triggers.sql
-- Description: Utility functions and auto-update triggers
-- ============================================================================

-- ============================================================================
-- 1. Generic utility functions
-- ============================================================================

-- 1.1 Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.update_updated_at() IS 'Auto-update updated_at column on row update';

-- 1.2 Convert GFX card format to standard format
-- GFX: "as", "kh", "10d" -> Standard: "As", "Kh", "Td"
CREATE OR REPLACE FUNCTION json.convert_gfx_card(gfx_card TEXT)
RETURNS VARCHAR(3) AS $$
DECLARE
    rank_part TEXT;
    suit_part TEXT;
BEGIN
    IF gfx_card IS NULL OR LENGTH(gfx_card) < 2 THEN
        RETURN NULL;
    END IF;

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

COMMENT ON FUNCTION json.convert_gfx_card(TEXT) IS 'Convert GFX card format (10d) to standard (Td)';

-- 1.3 Convert GFX hole cards array to normalized string
CREATE OR REPLACE FUNCTION json.convert_gfx_hole_cards(gfx_cards JSONB)
RETURNS VARCHAR(20) AS $$
DECLARE
    result TEXT := '';
    card_text TEXT;
BEGIN
    IF gfx_cards IS NULL OR jsonb_array_length(gfx_cards) = 0 THEN
        RETURN NULL;
    END IF;

    FOR card_text IN SELECT jsonb_array_elements_text(gfx_cards)
    LOOP
        result := result || json.convert_gfx_card(card_text);
    END LOOP;

    RETURN result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION json.convert_gfx_hole_cards(JSONB) IS 'Convert GFX hole cards array to normalized string';

-- 1.4 Format chip count for display
CREATE OR REPLACE FUNCTION public.format_chips(chips BIGINT)
RETURNS VARCHAR(20) AS $$
BEGIN
    IF chips IS NULL THEN
        RETURN NULL;
    ELSIF chips >= 1000000000 THEN
        RETURN ROUND(chips / 1000000000.0, 1)::TEXT || 'B';
    ELSIF chips >= 1000000 THEN
        RETURN ROUND(chips / 1000000.0, 1)::TEXT || 'M';
    ELSIF chips >= 1000 THEN
        RETURN ROUND(chips / 1000.0, 0)::TEXT || 'K';
    ELSE
        RETURN chips::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.format_chips(BIGINT) IS 'Format chip count: 1500000 -> 1.5M';

-- 1.5 Format currency for display
CREATE OR REPLACE FUNCTION public.format_currency(amount DECIMAL)
RETURNS VARCHAR(30) AS $$
BEGIN
    IF amount IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN '$' || TO_CHAR(amount, 'FM999,999,999,999');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.format_currency(DECIMAL) IS 'Format currency: 1500000 -> $1,500,000';

-- 1.6 Calculate BB count
CREATE OR REPLACE FUNCTION public.calculate_bb_count(chips BIGINT, big_blind INTEGER)
RETURNS DECIMAL(10,2) AS $$
BEGIN
    IF chips IS NULL OR big_blind IS NULL OR big_blind = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(chips::DECIMAL / big_blind, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.calculate_bb_count(BIGINT, INTEGER) IS 'Calculate big blind count from chips';

-- 1.7 Get or create player master record
CREATE OR REPLACE FUNCTION manual.get_or_create_player(
    p_name VARCHAR,
    p_nationality CHAR(2) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    player_id UUID;
BEGIN
    -- Try to find existing player
    SELECT id INTO player_id
    FROM manual.players_master
    WHERE name = p_name
      AND (nationality = p_nationality OR (nationality IS NULL AND p_nationality IS NULL))
    LIMIT 1;

    -- Create if not found
    IF player_id IS NULL THEN
        INSERT INTO manual.players_master (name, nationality)
        VALUES (p_name, p_nationality)
        RETURNING id INTO player_id;
    END IF;

    RETURN player_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION manual.get_or_create_player(VARCHAR, CHAR) IS 'Get existing or create new player master record';

-- ============================================================================
-- 2. Auto-update triggers for updated_at
-- ============================================================================

-- ae schema triggers
CREATE TRIGGER trg_ae_templates_updated
    BEFORE UPDATE ON ae.templates
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_ae_compositions_updated
    BEFORE UPDATE ON ae.compositions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_ae_layer_mappings_updated
    BEFORE UPDATE ON ae.layer_data_mappings
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_ae_data_types_updated
    BEFORE UPDATE ON ae.data_types
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_ae_render_jobs_updated
    BEFORE UPDATE ON ae.render_jobs
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- json schema triggers
CREATE TRIGGER trg_json_sessions_updated
    BEFORE UPDATE ON json.gfx_sessions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- wsop_plus schema triggers
CREATE TRIGGER trg_wsop_tournaments_updated
    BEFORE UPDATE ON wsop_plus.tournaments
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_wsop_blind_levels_updated
    BEFORE UPDATE ON wsop_plus.blind_levels
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_wsop_payouts_updated
    BEFORE UPDATE ON wsop_plus.payouts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_wsop_player_instances_updated
    BEFORE UPDATE ON wsop_plus.player_instances
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_wsop_schedules_updated
    BEFORE UPDATE ON wsop_plus.schedules
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Calculate schedule timestamps
CREATE OR REPLACE FUNCTION wsop_plus.calculate_schedule_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate start_timestamp
    NEW.start_timestamp := (NEW.date + NEW.time_start) AT TIME ZONE COALESCE(NEW.timezone, 'UTC');

    -- Calculate end_timestamp if time_end is set
    IF NEW.time_end IS NOT NULL THEN
        NEW.end_timestamp := (NEW.date + NEW.time_end) AT TIME ZONE COALESCE(NEW.timezone, 'UTC');
    ELSE
        NEW.end_timestamp := NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_wsop_schedules_calc_timestamps
    BEFORE INSERT OR UPDATE OF date, time_start, time_end, timezone ON wsop_plus.schedules
    FOR EACH ROW
    EXECUTE FUNCTION wsop_plus.calculate_schedule_timestamps();

-- manual schema triggers
CREATE TRIGGER trg_manual_players_updated
    BEFORE UPDATE ON manual.players_master
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_manual_profiles_updated
    BEFORE UPDATE ON manual.player_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_manual_commentators_updated
    BEFORE UPDATE ON manual.commentators
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_manual_venues_updated
    BEFORE UPDATE ON manual.venues
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_manual_events_updated
    BEFORE UPDATE ON manual.events
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_manual_feature_tables_updated
    BEFORE UPDATE ON manual.feature_tables
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_manual_seating_updated
    BEFORE UPDATE ON manual.seating_assignments
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================================
-- 3. Business logic triggers
-- ============================================================================

-- 3.1 Auto-update player ranks when chips change
CREATE OR REPLACE FUNCTION wsop_plus.update_player_ranks()
RETURNS TRIGGER AS $$
BEGIN
    -- Update ranks for all active players in the tournament
    WITH ranked AS (
        SELECT
            id,
            current_rank AS old_rank,
            ROW_NUMBER() OVER (ORDER BY chips DESC) AS new_rank
        FROM wsop_plus.player_instances
        WHERE tournament_id = NEW.tournament_id
          AND is_eliminated = FALSE
    )
    UPDATE wsop_plus.player_instances pi
    SET
        current_rank = r.new_rank,
        rank_change = COALESCE(r.old_rank, r.new_rank) - r.new_rank,
        previous_rank = r.old_rank
    FROM ranked r
    WHERE pi.id = r.id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_player_ranks
    AFTER UPDATE OF chips ON wsop_plus.player_instances
    FOR EACH ROW
    WHEN (OLD.chips IS DISTINCT FROM NEW.chips)
    EXECUTE FUNCTION wsop_plus.update_player_ranks();

-- 3.2 Update tournament statistics when player count changes
CREATE OR REPLACE FUNCTION wsop_plus.update_tournament_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update tournament player counts
    UPDATE wsop_plus.tournaments t
    SET
        remaining_players = (
            SELECT COUNT(*)
            FROM wsop_plus.player_instances
            WHERE tournament_id = t.id AND is_eliminated = FALSE
        ),
        avg_stack = (
            SELECT COALESCE(AVG(chips), 0)::INTEGER
            FROM wsop_plus.player_instances
            WHERE tournament_id = t.id AND is_eliminated = FALSE
        )
    WHERE t.id = COALESCE(NEW.tournament_id, OLD.tournament_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_tournament_stats
    AFTER INSERT OR UPDATE OF is_eliminated, chips OR DELETE ON wsop_plus.player_instances
    FOR EACH ROW
    EXECUTE FUNCTION wsop_plus.update_tournament_stats();

-- 3.3 Update hand player count on insert
CREATE OR REPLACE FUNCTION json.update_hand_player_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE json.hands
    SET player_count = (
        SELECT COUNT(*)
        FROM json.hand_players
        WHERE hand_id = NEW.hand_id
    )
    WHERE id = NEW.hand_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_hand_player_count
    AFTER INSERT ON json.hand_players
    FOR EACH ROW
    EXECUTE FUNCTION json.update_hand_player_count();

-- 3.4 Update hand action count on insert
CREATE OR REPLACE FUNCTION json.update_hand_action_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE json.hands
    SET action_count = (
        SELECT COUNT(*)
        FROM json.hand_actions
        WHERE hand_id = NEW.hand_id
    )
    WHERE id = NEW.hand_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_hand_action_count
    AFTER INSERT ON json.hand_actions
    FOR EACH ROW
    EXECUTE FUNCTION json.update_hand_action_count();

-- 3.5 Update session hand count
CREATE OR REPLACE FUNCTION json.update_session_hand_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE json.gfx_sessions
    SET
        total_hands = (
            SELECT COUNT(*)
            FROM json.hands
            WHERE gfx_session_id = COALESCE(NEW.gfx_session_id, OLD.gfx_session_id)
        ),
        premium_hands_count = (
            SELECT COUNT(*)
            FROM json.hands
            WHERE gfx_session_id = COALESCE(NEW.gfx_session_id, OLD.gfx_session_id)
              AND is_premium = TRUE
        )
    WHERE id = COALESCE(NEW.gfx_session_id, OLD.gfx_session_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_session_hand_count
    AFTER INSERT OR UPDATE OF is_premium OR DELETE ON json.hands
    FOR EACH ROW
    EXECUTE FUNCTION json.update_session_hand_count();

-- 3.6 Update composition layer counts
CREATE OR REPLACE FUNCTION ae.update_composition_layer_counts()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ae.compositions c
    SET
        layer_count = (SELECT COUNT(*) FROM ae.composition_layers WHERE composition_id = c.id),
        text_layer_count = (SELECT COUNT(*) FROM ae.composition_layers WHERE composition_id = c.id AND layer_type = 'text'),
        image_layer_count = (SELECT COUNT(*) FROM ae.composition_layers WHERE composition_id = c.id AND layer_type = 'image'),
        video_layer_count = (SELECT COUNT(*) FROM ae.composition_layers WHERE composition_id = c.id AND layer_type = 'video')
    WHERE c.id = COALESCE(NEW.composition_id, OLD.composition_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_composition_layer_counts
    AFTER INSERT OR DELETE OR UPDATE OF layer_type ON ae.composition_layers
    FOR EACH ROW
    EXECUTE FUNCTION ae.update_composition_layer_counts();

-- 3.7 Update template composition counts
CREATE OR REPLACE FUNCTION ae.update_template_counts()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ae.templates t
    SET
        composition_count = (SELECT COUNT(*) FROM ae.compositions WHERE template_id = t.id),
        text_layer_count = (
            SELECT COALESCE(SUM(c.text_layer_count), 0)
            FROM ae.compositions c
            WHERE c.template_id = t.id
        )
    WHERE t.id = COALESCE(NEW.template_id, OLD.template_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_template_counts
    AFTER INSERT OR DELETE OR UPDATE OF text_layer_count ON ae.compositions
    FOR EACH ROW
    EXECUTE FUNCTION ae.update_template_counts();

-- 3.8 Feature table player count update
CREATE OR REPLACE FUNCTION manual.update_feature_table_player_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE manual.feature_tables ft
    SET current_player_count = (
        SELECT COUNT(*)
        FROM manual.seating_assignments
        WHERE feature_table_id = ft.id AND is_current = TRUE
    )
    WHERE ft.id = COALESCE(NEW.feature_table_id, OLD.feature_table_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_feature_table_player_count
    AFTER INSERT OR UPDATE OF is_current OR DELETE ON manual.seating_assignments
    FOR EACH ROW
    EXECUTE FUNCTION manual.update_feature_table_player_count();
