-- ============================================================================
-- Migration: 20260110000300_wsop_plus_schema_tables.sql
-- Description: Tournament operations from WSOP+ CSV
-- Schema: wsop_plus
-- Tables: 5 (tournaments, blind_levels, payouts, player_instances, schedules)
-- ============================================================================

-- ============================================================================
-- 1. wsop_plus.tournaments - Tournament information
-- ============================================================================
CREATE TABLE wsop_plus.tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Basic info
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(100),
    tournament_number INTEGER,
    tournament_code VARCHAR(50),

    -- Buy-in structure
    buy_in DECIMAL(10,2) NOT NULL,
    rake DECIMAL(10,2) DEFAULT 0,
    total_cost DECIMAL(10,2) GENERATED ALWAYS AS (buy_in + rake) STORED,
    starting_chips INTEGER NOT NULL,

    -- Current state
    current_level INTEGER DEFAULT 1,
    current_day INTEGER DEFAULT 1,
    current_break_until TIMESTAMPTZ,

    -- Player counts
    registered_players INTEGER DEFAULT 0,
    remaining_players INTEGER DEFAULT 0,
    unique_players INTEGER DEFAULT 0,
    reentries INTEGER DEFAULT 0,
    addons INTEGER DEFAULT 0,

    -- Prize pool
    prize_pool DECIMAL(15,2) DEFAULT 0,
    guaranteed_prize DECIMAL(15,2),
    overlay DECIMAL(15,2) GENERATED ALWAYS AS (
        GREATEST(0, COALESCE(guaranteed_prize, 0) - prize_pool)
    ) STORED,
    places_paid INTEGER,

    -- Bubble info
    bubble_line INTEGER,
    is_itm BOOLEAN DEFAULT FALSE,
    itm_at TIMESTAMPTZ,

    -- Registration
    is_registration_open BOOLEAN DEFAULT TRUE,
    registration_closes_at TIMESTAMPTZ,
    late_registration_levels INTEGER,

    -- Statistics
    avg_stack INTEGER,
    median_stack INTEGER,
    chip_leader_chips BIGINT,
    chip_leader_name VARCHAR(255),

    -- Timing
    scheduled_start TIMESTAMPTZ,
    actual_start TIMESTAMPTZ,
    estimated_end TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,

    -- Status
    status VARCHAR(20) DEFAULT 'scheduled',

    -- Cross-references (soft FK)
    event_id UUID,
    venue_id UUID,

    -- Import tracking
    import_source VARCHAR(100),
    import_row_id INTEGER,
    imported_at TIMESTAMPTZ,
    last_sync_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT tournaments_code_unique UNIQUE (tournament_code)
);

COMMENT ON TABLE wsop_plus.tournaments IS 'Tournament information from WSOP+ CSV';
COMMENT ON COLUMN wsop_plus.tournaments.status IS 'Status: scheduled, registration, running, paused, final_table, completed, cancelled';
COMMENT ON COLUMN wsop_plus.tournaments.tournament_number IS 'WSOP Event number (Event #1, #2, etc.)';
COMMENT ON COLUMN wsop_plus.tournaments.event_id IS 'Soft FK to manual.events';
COMMENT ON COLUMN wsop_plus.tournaments.venue_id IS 'Soft FK to manual.venues';

-- ============================================================================
-- 2. wsop_plus.blind_levels - Blind structure
-- ============================================================================
CREATE TABLE wsop_plus.blind_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES wsop_plus.tournaments(id) ON DELETE CASCADE,

    -- Level info
    level_number INTEGER NOT NULL,
    level_name VARCHAR(50),

    -- Blinds
    small_blind INTEGER NOT NULL,
    big_blind INTEGER NOT NULL,
    ante INTEGER DEFAULT 0,
    big_blind_ante INTEGER DEFAULT 0,

    -- Formatted strings (for display)
    blinds_display VARCHAR(50) GENERATED ALWAYS AS (
        small_blind::text || ' / ' || big_blind::text ||
        CASE WHEN COALESCE(big_blind_ante, ante) > 0
             THEN ' - ' || COALESCE(big_blind_ante, ante)::text
             ELSE '' END
    ) STORED,

    -- Duration
    duration_minutes INTEGER NOT NULL,
    is_break BOOLEAN DEFAULT FALSE,
    break_duration_minutes INTEGER,
    break_name VARCHAR(100),

    -- Current state
    is_current BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    paused_at TIMESTAMPTZ,
    time_remaining_seconds INTEGER,

    -- Statistics at this level
    players_at_start INTEGER,
    avg_stack_at_start INTEGER,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tournament_id, level_number)
);

COMMENT ON TABLE wsop_plus.blind_levels IS 'Blind structure and level progression';
COMMENT ON COLUMN wsop_plus.blind_levels.big_blind_ante IS 'BB ante (one player posts entire table ante)';
COMMENT ON COLUMN wsop_plus.blind_levels.is_break IS 'TRUE if this is a scheduled break';

-- ============================================================================
-- 3. wsop_plus.payouts - Prize structure
-- ============================================================================
CREATE TABLE wsop_plus.payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES wsop_plus.tournaments(id) ON DELETE CASCADE,

    -- Place range
    place_start INTEGER NOT NULL,
    place_end INTEGER NOT NULL,
    place_display VARCHAR(20) GENERATED ALWAYS AS (
        CASE WHEN place_start = place_end
             THEN place_start::text
             ELSE place_start::text || '-' || place_end::text END
    ) STORED,

    -- Payout
    amount DECIMAL(12,2) NOT NULL,
    percentage DECIMAL(5,2),
    formatted_amount VARCHAR(50),

    -- Status
    is_current_bubble BOOLEAN DEFAULT FALSE,
    is_reached BOOLEAN DEFAULT FALSE,
    reached_at TIMESTAMPTZ,

    -- For player link (when place reached)
    player_id UUID,
    player_name VARCHAR(255),

    -- Special awards
    is_bracelet BOOLEAN DEFAULT FALSE,
    is_ring BOOLEAN DEFAULT FALSE,
    bonus_amount DECIMAL(12,2),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tournament_id, place_start, place_end)
);

COMMENT ON TABLE wsop_plus.payouts IS 'Prize payout structure';
COMMENT ON COLUMN wsop_plus.payouts.place_display IS 'Display format: "1", "5-6", "10-12"';
COMMENT ON COLUMN wsop_plus.payouts.percentage IS 'Percentage of prize pool';
COMMENT ON COLUMN wsop_plus.payouts.is_current_bubble IS 'TRUE if this is the current bubble spot';

-- ============================================================================
-- 4. wsop_plus.player_instances - Tournament participants
-- ============================================================================
CREATE TABLE wsop_plus.player_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES wsop_plus.tournaments(id) ON DELETE CASCADE,

    -- Player identification
    player_name VARCHAR(255) NOT NULL,
    player_display_name VARCHAR(255),
    seat_number INTEGER CHECK (seat_number BETWEEN 1 AND 10),
    table_number INTEGER,

    -- Stack info
    chips BIGINT NOT NULL DEFAULT 0,
    chips_at_start_of_day BIGINT,
    peak_chips BIGINT,
    low_chips BIGINT,

    -- Rankings
    current_rank INTEGER,
    rank_change INTEGER DEFAULT 0,
    previous_rank INTEGER,

    -- BB count
    bb_count DECIMAL(10,2),
    avg_stack_percentage DECIMAL(6,2),

    -- Status
    is_eliminated BOOLEAN DEFAULT FALSE,
    eliminated_at TIMESTAMPTZ,
    eliminator_id UUID,
    eliminator_name VARCHAR(255),
    elimination_hand VARCHAR(100),

    -- Final result
    final_rank INTEGER,
    payout_received DECIMAL(12,2),
    bounty_received DECIMAL(12,2),

    -- Entry info
    entry_count INTEGER DEFAULT 1,
    entry_type VARCHAR(20) DEFAULT 'initial',
    registration_time TIMESTAMPTZ DEFAULT NOW(),
    last_reentry_time TIMESTAMPTZ,

    -- Feature table tracking
    is_feature_table BOOLEAN DEFAULT FALSE,
    feature_table_since TIMESTAMPTZ,

    -- Cross-references (soft FK)
    player_master_id UUID,
    feature_table_id UUID,

    -- Import tracking
    import_row_id INTEGER,
    last_sync_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tournament_id, player_name, entry_count)
);

COMMENT ON TABLE wsop_plus.player_instances IS 'Tournament participant instances (one per entry)';
COMMENT ON COLUMN wsop_plus.player_instances.entry_type IS 'Type: initial, reentry, addon';
COMMENT ON COLUMN wsop_plus.player_instances.bb_count IS 'Chips / Big Blind';
COMMENT ON COLUMN wsop_plus.player_instances.player_master_id IS 'Soft FK to manual.players_master';
COMMENT ON COLUMN wsop_plus.player_instances.feature_table_id IS 'Soft FK to manual.feature_tables';

-- ============================================================================
-- 5. wsop_plus.schedules - Broadcast schedule
-- ============================================================================
CREATE TABLE wsop_plus.schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Date/Time
    date DATE NOT NULL,
    time_start TIME NOT NULL,
    time_end TIME,
    timezone VARCHAR(50) DEFAULT 'UTC',

    -- Calculated timestamps (set via trigger or application)
    start_timestamp TIMESTAMPTZ,
    end_timestamp TIMESTAMPTZ,

    -- Event info
    event_title VARCHAR(255) NOT NULL,
    event_subtitle VARCHAR(255),
    description TEXT,

    -- Broadcast info
    channel VARCHAR(100),
    stream_url TEXT,
    is_live BOOLEAN DEFAULT FALSE,
    is_replay BOOLEAN DEFAULT FALSE,

    -- Status
    status VARCHAR(20) DEFAULT 'scheduled',
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,

    -- Cross-references (soft FK)
    event_id UUID,
    tournament_id UUID REFERENCES wsop_plus.tournaments(id) ON DELETE SET NULL,
    venue_id UUID,

    -- Graphics
    thumbnail_url TEXT,
    banner_url TEXT,

    -- Import tracking
    import_source VARCHAR(100),
    last_sync_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE wsop_plus.schedules IS 'Broadcast schedule for streaming';
COMMENT ON COLUMN wsop_plus.schedules.channel IS 'Channel: WSOP+, PokerGO, YouTube, etc.';
COMMENT ON COLUMN wsop_plus.schedules.status IS 'Status: scheduled, live, completed, cancelled, postponed';
COMMENT ON COLUMN wsop_plus.schedules.event_id IS 'Soft FK to manual.events';
COMMENT ON COLUMN wsop_plus.schedules.venue_id IS 'Soft FK to manual.venues';
