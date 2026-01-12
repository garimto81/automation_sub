-- ============================================================
-- Phase 3: Hand System Tables (6개)
-- Supabase SQL Editor에서 실행
-- ============================================================

-- 020: gfx_sessions
CREATE TABLE IF NOT EXISTS gfx_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    feature_table_id UUID REFERENCES feature_tables(id) ON DELETE SET NULL,
    gfx_id BIGINT UNIQUE NOT NULL,
    event_title VARCHAR(255),
    table_type VARCHAR(50) NOT NULL,
    software_version VARCHAR(50),
    payouts JSONB DEFAULT '[]',
    status VARCHAR(20) DEFAULT 'active',
    total_hands INTEGER DEFAULT 0,
    created_at_gfx TIMESTAMPTZ,
    source_file VARCHAR(500),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 021: hands
CREATE TABLE IF NOT EXISTS hands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gfx_session_id UUID REFERENCES gfx_sessions(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    hand_number INTEGER NOT NULL,
    table_number INTEGER,
    game_variant VARCHAR(20) NOT NULL DEFAULT 'HOLDEM',
    game_class VARCHAR(20) NOT NULL DEFAULT 'FLOP',
    bet_structure VARCHAR(20) NOT NULL DEFAULT 'NOLIMIT',
    button_seat INTEGER,
    small_blind_seat INTEGER,
    big_blind_seat INTEGER,
    small_blind_amount DECIMAL(12,2),
    big_blind_amount DECIMAL(12,2),
    ante_amount DECIMAL(12,2) DEFAULT 0,
    ante_type VARCHAR(30),
    level_number INTEGER,
    pot_size DECIMAL(12,2),
    num_boards INTEGER DEFAULT 1,
    run_it_num_times INTEGER DEFAULT 1,
    winner_id UUID REFERENCES players_master(id) ON DELETE SET NULL,
    winning_hand VARCHAR(50),
    grade CHAR(1),
    is_premium BOOLEAN DEFAULT FALSE,
    grade_factors JSONB DEFAULT '{}',
    duration INTERVAL,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 022: hand_players
CREATE TABLE IF NOT EXISTS hand_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players_master(id) ON DELETE CASCADE,
    player_instance_id UUID REFERENCES player_instances(id) ON DELETE SET NULL,
    seat_number INTEGER NOT NULL,
    start_stack BIGINT NOT NULL,
    end_stack BIGINT NOT NULL,
    stack_delta BIGINT GENERATED ALWAYS AS (end_stack - start_stack) STORED,
    cumulative_winnings BIGINT DEFAULT 0,
    hole_cards VARCHAR(10),
    sitting_out BOOLEAN DEFAULT FALSE,
    is_winner BOOLEAN DEFAULT FALSE,
    vpip_percent DECIMAL(5,2),
    pfr_percent DECIMAL(5,2),
    aggression_percent DECIMAL(5,2),
    wtsd_percent DECIMAL(5,2),
    elimination_rank INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(hand_id, seat_number)
);

-- 023: hand_actions
CREATE TABLE IF NOT EXISTS hand_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,
    player_id UUID REFERENCES players_master(id) ON DELETE SET NULL,
    action_order INTEGER NOT NULL,
    street VARCHAR(20) NOT NULL,
    action VARCHAR(20) NOT NULL,
    seat_number INTEGER,
    bet_amount DECIMAL(12,2),
    pot_size_after DECIMAL(12,2),
    board_num INTEGER DEFAULT 0,
    num_cards_drawn INTEGER DEFAULT 0,
    action_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 024: hand_cards (신규 통합)
CREATE TABLE IF NOT EXISTS hand_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,
    card_rank CHAR(2) NOT NULL,
    card_suit CHAR(1) NOT NULL,
    card_type VARCHAR(20) NOT NULL,
    seat_number INTEGER,
    card_order INTEGER,
    board_num INTEGER DEFAULT 0,
    gfx_card VARCHAR(10),
    source VARCHAR(20) DEFAULT 'gfx',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 025: chip_flow (신규)
CREATE TABLE IF NOT EXISTS chip_flow (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES player_instances(id) ON DELETE CASCADE,
    hand_id UUID REFERENCES hands(id) ON DELETE SET NULL,
    delta BIGINT NOT NULL,
    reason VARCHAR(50),
    running_total BIGINT NOT NULL,
    hand_number INTEGER,
    level_number INTEGER,
    bb_count DECIMAL(10,2),
    avg_stack_percentage DECIMAL(6,2),
    source VARCHAR(20) DEFAULT 'gfx',
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_gfx_id ON gfx_sessions(gfx_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_tournament ON gfx_sessions(tournament_id);
CREATE INDEX IF NOT EXISTS idx_hands_gfx_session ON hands(gfx_session_id);
CREATE INDEX IF NOT EXISTS idx_hands_tournament ON hands(tournament_id);
CREATE INDEX IF NOT EXISTS idx_hands_number ON hands(hand_number);
CREATE INDEX IF NOT EXISTS idx_hands_grade ON hands(grade) WHERE grade IN ('A', 'B');
CREATE INDEX IF NOT EXISTS idx_hand_players_hand ON hand_players(hand_id);
CREATE INDEX IF NOT EXISTS idx_hand_players_player ON hand_players(player_id);
CREATE INDEX IF NOT EXISTS idx_hand_actions_hand ON hand_actions(hand_id);
CREATE INDEX IF NOT EXISTS idx_hand_actions_order ON hand_actions(hand_id, action_order);
CREATE INDEX IF NOT EXISTS idx_hand_cards_hand ON hand_cards(hand_id);
CREATE INDEX IF NOT EXISTS idx_hand_cards_type ON hand_cards(card_type);
CREATE INDEX IF NOT EXISTS idx_chip_flow_instance ON chip_flow(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_chip_flow_timestamp ON chip_flow(timestamp DESC);
