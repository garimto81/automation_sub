-- ============================================================
-- Phase 5: Views & Functions
-- Supabase SQL Editor에서 실행
-- ============================================================

-- ============================================================
-- Views
-- ============================================================

-- v_tournament_leaderboard
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

-- v_feature_table_players
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

-- v_premium_hands
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

-- v_pending_graphics
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

-- ============================================================
-- Functions
-- ============================================================

-- convert_gfx_card
CREATE OR REPLACE FUNCTION convert_gfx_card(gfx_card TEXT)
RETURNS TEXT AS $$
DECLARE
    card_rank TEXT;
    card_suit TEXT;
BEGIN
    IF gfx_card IS NULL OR LENGTH(gfx_card) < 2 THEN
        RETURN NULL;
    END IF;
    card_suit := LOWER(RIGHT(gfx_card, 1));
    card_rank := UPPER(LEFT(gfx_card, LENGTH(gfx_card) - 1));
    IF card_rank = '10' THEN
        card_rank := 'T';
    END IF;
    RETURN card_rank || card_suit;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- convert_gfx_hole_cards
CREATE OR REPLACE FUNCTION convert_gfx_hole_cards(hole_cards JSONB)
RETURNS TEXT AS $$
DECLARE
    card1 TEXT;
    card2 TEXT;
    cards_text TEXT;
BEGIN
    IF hole_cards IS NULL OR jsonb_array_length(hole_cards) < 1 THEN
        RETURN NULL;
    END IF;
    cards_text := hole_cards->>0;
    IF cards_text LIKE '% %' THEN
        card1 := convert_gfx_card(SPLIT_PART(cards_text, ' ', 1));
        card2 := convert_gfx_card(SPLIT_PART(cards_text, ' ', 2));
    ELSIF jsonb_array_length(hole_cards) >= 2 THEN
        card1 := convert_gfx_card(hole_cards->>0);
        card2 := convert_gfx_card(hole_cards->>1);
    ELSE
        RETURN NULL;
    END IF;
    RETURN card1 || card2;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- calculate_bb_count
CREATE OR REPLACE FUNCTION calculate_bb_count(chips BIGINT, big_blind INTEGER)
RETURNS DECIMAL(10,2) AS $$
BEGIN
    IF big_blind IS NULL OR big_blind = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(chips::DECIMAL / big_blind, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- update_player_ranks
CREATE OR REPLACE FUNCTION update_player_ranks(p_tournament_id UUID)
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER := 0;
BEGIN
    WITH ranked AS (
        SELECT
            id,
            current_rank AS old_rank,
            ROW_NUMBER() OVER (ORDER BY chips DESC) AS new_rank
        FROM player_instances
        WHERE tournament_id = p_tournament_id
          AND is_eliminated = FALSE
    )
    UPDATE player_instances pi
    SET
        current_rank = r.new_rank,
        rank_change = COALESCE(r.old_rank, r.new_rank) - r.new_rank,
        updated_at = NOW()
    FROM ranked r
    WHERE pi.id = r.id;
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- get_or_create_player_master
CREATE OR REPLACE FUNCTION get_or_create_player_master(
    p_name TEXT,
    p_nationality CHAR(2) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_player_id UUID;
BEGIN
    SELECT id INTO v_player_id FROM players_master WHERE LOWER(name) = LOWER(p_name);
    IF v_player_id IS NULL THEN
        INSERT INTO players_master (name, nationality) VALUES (p_name, p_nationality)
        RETURNING id INTO v_player_id;
    END IF;
    RETURN v_player_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Triggers
-- ============================================================

-- log_chip_flow trigger function
CREATE OR REPLACE FUNCTION log_chip_flow()
RETURNS TRIGGER AS $$
DECLARE
    v_level_number INTEGER;
    v_big_blind INTEGER;
BEGIN
    IF OLD.chips = NEW.chips THEN
        RETURN NEW;
    END IF;
    SELECT bl.level_number, bl.big_blind INTO v_level_number, v_big_blind
    FROM blind_levels bl
    WHERE bl.tournament_id = NEW.tournament_id AND bl.is_current = TRUE
    LIMIT 1;
    INSERT INTO chip_flow (player_instance_id, delta, reason, running_total, level_number, bb_count, source)
    VALUES (
        NEW.id,
        NEW.chips - OLD.chips,
        CASE WHEN NEW.chips > OLD.chips THEN 'pot_win' ELSE 'pot_loss' END,
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

-- updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER trg_venues_updated_at BEFORE UPDATE ON venues FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_tournaments_updated_at BEFORE UPDATE ON tournaments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_players_master_updated_at BEFORE UPDATE ON players_master FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_player_instances_updated_at BEFORE UPDATE ON player_instances FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_feature_tables_updated_at BEFORE UPDATE ON feature_tables FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_gfx_sessions_updated_at BEFORE UPDATE ON gfx_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_commentators_updated_at BEFORE UPDATE ON commentators FOR EACH ROW EXECUTE FUNCTION update_updated_at();
