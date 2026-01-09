-- ============================================================================
-- Migration: 20260110000200_json_schema_tables.sql
-- Description: pokerGFX RFID real-time hand data tables
-- Schema: json
-- Tables: 6 (gfx_sessions, hands, hand_players, hand_actions, hand_cards, hand_results)
-- ============================================================================

-- ============================================================================
-- 1. json.gfx_sessions - PokerGFX session metadata
-- ============================================================================
CREATE TABLE json.gfx_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gfx_id BIGINT UNIQUE NOT NULL,
    event_title VARCHAR(255),
    table_type VARCHAR(50) NOT NULL DEFAULT 'FEATURE_TABLE',
    software_version VARCHAR(50),
    payouts JSONB DEFAULT '[]',
    status VARCHAR(20) DEFAULT 'active',
    total_hands INTEGER DEFAULT 0,
    avg_hand_duration INTERVAL,
    premium_hands_count INTEGER DEFAULT 0,
    created_at_gfx TIMESTAMPTZ,
    source_file VARCHAR(500),
    source_checksum VARCHAR(64),
    tournament_id UUID,
    feature_table_id UUID,
    event_id UUID,
    import_status VARCHAR(30) DEFAULT 'complete',
    import_errors JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE json.gfx_sessions IS 'PokerGFX RFID session data (one per JSON file)';
COMMENT ON COLUMN json.gfx_sessions.gfx_id IS 'Windows FileTime format ID (unique across all sessions)';
COMMENT ON COLUMN json.gfx_sessions.table_type IS 'Table type: FEATURE_TABLE, OUTER_TABLE, FINAL_TABLE';
COMMENT ON COLUMN json.gfx_sessions.payouts IS 'Embedded payout array from session JSON';
COMMENT ON COLUMN json.gfx_sessions.tournament_id IS 'Soft FK to wsop_plus.tournaments';
COMMENT ON COLUMN json.gfx_sessions.feature_table_id IS 'Soft FK to manual.feature_tables';

-- ============================================================================
-- 2. json.hands - Hand metadata
-- ============================================================================
CREATE TABLE json.hands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gfx_session_id UUID NOT NULL REFERENCES json.gfx_sessions(id) ON DELETE CASCADE,
    hand_number INTEGER NOT NULL,
    table_number INTEGER,

    -- Game settings
    game_variant VARCHAR(20) NOT NULL DEFAULT 'HOLDEM',
    game_class VARCHAR(20) NOT NULL DEFAULT 'FLOP',
    bet_structure VARCHAR(20) NOT NULL DEFAULT 'NOLIMIT',

    -- Positions
    button_seat INTEGER CHECK (button_seat BETWEEN 1 AND 10),
    small_blind_seat INTEGER CHECK (small_blind_seat BETWEEN 1 AND 10),
    big_blind_seat INTEGER CHECK (big_blind_seat BETWEEN 1 AND 10),

    -- Blinds/Antes
    small_blind_amount DECIMAL(12,2),
    big_blind_amount DECIMAL(12,2),
    ante_amount DECIMAL(12,2) DEFAULT 0,
    ante_type VARCHAR(30),
    level_number INTEGER,

    -- Hand results
    pot_size DECIMAL(12,2),
    final_pot_size DECIMAL(12,2),
    num_boards INTEGER DEFAULT 1,
    run_it_num_times INTEGER DEFAULT 1,

    -- Winner info (denormalized for quick access)
    winner_seat INTEGER,
    winner_player_name VARCHAR(255),
    winning_hand VARCHAR(100),
    winning_hand_rank VARCHAR(50),
    winning_rank_value INTEGER,

    -- Grading
    grade CHAR(1) CHECK (grade IN ('A', 'B', 'C', 'D', 'F')),
    is_premium BOOLEAN DEFAULT FALSE,
    is_all_in BOOLEAN DEFAULT FALSE,
    is_showdown BOOLEAN DEFAULT FALSE,
    grade_factors JSONB DEFAULT '{}',

    -- Community cards (denormalized for quick access)
    flop_cards JSONB,
    turn_card VARCHAR(3),
    river_card VARCHAR(3),

    -- Timing
    duration INTERVAL,
    duration_seconds INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM duration)::INTEGER
    ) STORED,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    -- Stats
    player_count INTEGER,
    action_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(gfx_session_id, hand_number)
);

COMMENT ON TABLE json.hands IS 'Individual poker hands from GFX sessions';
COMMENT ON COLUMN json.hands.game_variant IS 'Variant: HOLDEM, OMAHA, STUD, RAZZ, DRAW';
COMMENT ON COLUMN json.hands.game_class IS 'Class: FLOP, DRAW, STUD';
COMMENT ON COLUMN json.hands.bet_structure IS 'Structure: NOLIMIT, POTLIMIT, LIMIT';
COMMENT ON COLUMN json.hands.ante_type IS 'Type: BB_ANTE_BB1ST, ANTE_ALL, ANTE_BUTTON';
COMMENT ON COLUMN json.hands.grade IS 'Quality grade: A (best) to F (poor)';
COMMENT ON COLUMN json.hands.winning_rank_value IS 'phevaluator rank: 1 (Royal Flush) to 7462 (worst high card)';

-- ============================================================================
-- 3. json.hand_players - Per-hand player state
-- ============================================================================
CREATE TABLE json.hand_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES json.hands(id) ON DELETE CASCADE,

    -- Player identification
    seat_number INTEGER NOT NULL CHECK (seat_number BETWEEN 1 AND 10),
    player_name VARCHAR(255) NOT NULL,
    player_long_name VARCHAR(500),

    -- Stack tracking
    start_stack BIGINT NOT NULL,
    end_stack BIGINT NOT NULL,
    stack_delta BIGINT GENERATED ALWAYS AS (end_stack - start_stack) STORED,
    cumulative_winnings BIGINT DEFAULT 0,

    -- Hole cards
    hole_cards JSONB,
    hole_cards_normalized VARCHAR(10),
    hole_card_1 VARCHAR(3),
    hole_card_2 VARCHAR(3),
    hole_card_3 VARCHAR(3),
    hole_card_4 VARCHAR(3),

    -- Status flags
    sitting_out BOOLEAN DEFAULT FALSE,
    is_winner BOOLEAN DEFAULT FALSE,
    is_all_in BOOLEAN DEFAULT FALSE,
    went_to_showdown BOOLEAN DEFAULT FALSE,

    -- Hand result
    won_amount DECIMAL(12,2) DEFAULT 0,
    hand_description VARCHAR(100),
    hand_rank VARCHAR(50),
    rank_value INTEGER,
    board_num INTEGER DEFAULT 0,

    -- Stats from GFX
    vpip_percent DECIMAL(5,2),
    pfr_percent DECIMAL(5,2),
    aggression_percent DECIMAL(5,2),
    wtsd_percent DECIMAL(5,2),

    -- Actions summary
    preflop_action VARCHAR(20),
    final_action VARCHAR(20),
    total_bet_amount DECIMAL(12,2) DEFAULT 0,

    -- Elimination
    elimination_rank INTEGER,
    is_eliminated BOOLEAN DEFAULT FALSE,

    -- Cross-reference
    player_master_id UUID,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(hand_id, seat_number)
);

COMMENT ON TABLE json.hand_players IS 'Player state for each hand';
COMMENT ON COLUMN json.hand_players.hole_cards IS 'Array format: ["As", "Kh"] or ["Tc", "Td", "9h", "8h"] for Omaha';
COMMENT ON COLUMN json.hand_players.hole_cards_normalized IS 'Normalized format: AsKh, TcTd9h8h';
COMMENT ON COLUMN json.hand_players.rank_value IS 'phevaluator: 1 (best) to 7462 (worst)';
COMMENT ON COLUMN json.hand_players.elimination_rank IS '-1 if active, 1+ for final placement';
COMMENT ON COLUMN json.hand_players.player_master_id IS 'Soft FK to manual.players_master';

-- ============================================================================
-- 4. json.hand_actions - Action log (event sourcing)
-- ============================================================================
CREATE TABLE json.hand_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES json.hands(id) ON DELETE CASCADE,

    -- Ordering
    action_order INTEGER NOT NULL,
    street VARCHAR(20) NOT NULL,
    street_order INTEGER,

    -- Event from GFX
    event_type VARCHAR(30) NOT NULL,

    -- Action details
    action VARCHAR(20) NOT NULL,
    seat_number INTEGER CHECK (seat_number BETWEEN 1 AND 10),
    player_name VARCHAR(255),

    -- Amounts
    bet_amount DECIMAL(12,2),
    raise_to_amount DECIMAL(12,2),
    pot_size_before DECIMAL(12,2),
    pot_size_after DECIMAL(12,2),

    -- For draw games
    num_cards_drawn INTEGER DEFAULT 0,
    cards_drawn JSONB,

    -- For board cards
    board_num INTEGER DEFAULT 0,
    board_cards JSONB,

    -- Timing
    action_time TIMESTAMPTZ,
    time_to_act_seconds INTEGER,

    -- Raw GFX data
    gfx_event_data JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE json.hand_actions IS 'Action-by-action event log (event sourcing pattern)';
COMMENT ON COLUMN json.hand_actions.street IS 'Street: preflop, flop, turn, river, showdown, draw1, draw2, draw3';
COMMENT ON COLUMN json.hand_actions.event_type IS 'GFX EventType: FOLD, CHECK, CALL, BET, RAISE, ALL_IN, BOARD_CARD, SHOWDOWN, DRAW, etc.';
COMMENT ON COLUMN json.hand_actions.action IS 'Normalized action: fold, check, call, bet, raise, all-in, show, muck';

-- ============================================================================
-- 5. json.hand_cards - Community/hole cards (normalized)
-- ============================================================================
CREATE TABLE json.hand_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES json.hands(id) ON DELETE CASCADE,

    -- Card info
    card_rank VARCHAR(2) NOT NULL,
    card_suit CHAR(1) NOT NULL,
    card_normalized VARCHAR(3) GENERATED ALWAYS AS (
        card_rank || card_suit
    ) STORED,

    -- Location
    card_type VARCHAR(20) NOT NULL,
    seat_number INTEGER CHECK (seat_number BETWEEN 1 AND 10),
    card_order INTEGER,
    board_num INTEGER DEFAULT 0,

    -- Original GFX format
    gfx_card VARCHAR(10),

    -- Source tracking
    source VARCHAR(20) DEFAULT 'gfx',
    confidence DECIMAL(3,2) DEFAULT 1.0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE json.hand_cards IS 'Individual cards (community + hole cards)';
COMMENT ON COLUMN json.hand_cards.card_rank IS 'Rank: A, K, Q, J, T, 9, 8, 7, 6, 5, 4, 3, 2';
COMMENT ON COLUMN json.hand_cards.card_suit IS 'Suit: h (hearts), d (diamonds), c (clubs), s (spades)';
COMMENT ON COLUMN json.hand_cards.card_type IS 'Type: hole, flop, turn, river, draw';
COMMENT ON COLUMN json.hand_cards.gfx_card IS 'Original GFX format: as, kh, 10d (10 instead of T)';
COMMENT ON COLUMN json.hand_cards.source IS 'Source: gfx, manual, ai (vision inference)';

-- ============================================================================
-- 6. json.hand_results - Hand results (per player per board)
-- ============================================================================
CREATE TABLE json.hand_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES json.hands(id) ON DELETE CASCADE,

    -- Player
    seat_number INTEGER NOT NULL CHECK (seat_number BETWEEN 1 AND 10),
    player_name VARCHAR(255),

    -- Result
    is_winner BOOLEAN NOT NULL,
    won_amount DECIMAL(12,2) DEFAULT 0,
    pot_contribution DECIMAL(12,2) DEFAULT 0,
    net_result DECIMAL(12,2) GENERATED ALWAYS AS (won_amount - pot_contribution) STORED,

    -- Hand ranking
    hand_description VARCHAR(100),
    hand_rank VARCHAR(50),
    rank_value INTEGER,
    kickers JSONB,

    -- Cards used
    cards_used JSONB,
    best_five JSONB,

    -- Run It Twice support
    board_num INTEGER DEFAULT 0,

    -- Side pots
    main_pot_won DECIMAL(12,2),
    side_pot_won DECIMAL(12,2),

    -- Position
    showdown_order INTEGER,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(hand_id, seat_number, board_num)
);

COMMENT ON TABLE json.hand_results IS 'Final hand results per player per board';
COMMENT ON COLUMN json.hand_results.hand_rank IS 'Category: Royal Flush, Straight Flush, Four of a Kind, Full House, Flush, Straight, Three of a Kind, Two Pair, One Pair, High Card';
COMMENT ON COLUMN json.hand_results.rank_value IS 'phevaluator: 1 (Royal Flush) to 7462 (7-5-4-3-2 high)';
COMMENT ON COLUMN json.hand_results.kickers IS 'Kicker cards array: ["K", "Q", "9"]';
COMMENT ON COLUMN json.hand_results.best_five IS 'Best 5-card hand: ["As", "Ks", "Qs", "Js", "Ts"]';
COMMENT ON COLUMN json.hand_results.board_num IS '0 for single board, 1+ for Run It Twice/Thrice';
