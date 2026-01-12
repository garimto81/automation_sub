-- ============================================================
-- Phase 2: Player System Tables (4개)
-- Supabase SQL Editor에서 실행
-- ============================================================

-- 010: players_master (신규 마스터 테이블)
CREATE TABLE IF NOT EXISTS players_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    nationality CHAR(2),
    photo_url TEXT,
    hendon_mob_id VARCHAR(50) UNIQUE,
    gpi_id VARCHAR(50) UNIQUE,
    wsop_bracelets INTEGER DEFAULT 0,
    wsop_rings INTEGER DEFAULT 0,
    wsop_final_tables INTEGER DEFAULT 0,
    total_earnings DECIMAL(15,2) DEFAULT 0,
    total_final_tables INTEGER DEFAULT 0,
    biography TEXT,
    notable_wins JSONB DEFAULT '[]',
    hometown VARCHAR(255),
    profession VARCHAR(255),
    social_links JSONB DEFAULT '{}',
    is_key_player BOOLEAN DEFAULT FALSE,
    key_player_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT players_master_name_unique UNIQUE (name)
);

-- 011: feature_tables
CREATE TABLE IF NOT EXISTS feature_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    table_number INTEGER NOT NULL,
    table_name VARCHAR(100),
    rfid_device_id VARCHAR(100),
    gfx_table_id VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    is_streaming BOOLEAN DEFAULT FALSE,
    camera_config JSONB DEFAULT '{}',
    activated_at TIMESTAMPTZ,
    deactivated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tournament_id, table_number)
);

-- 012: player_instances (신규 인스턴스 테이블)
CREATE TABLE IF NOT EXISTS player_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players_master(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    chips BIGINT NOT NULL DEFAULT 0,
    seat_number INTEGER,
    table_number INTEGER,
    feature_table_id UUID REFERENCES feature_tables(id) ON DELETE SET NULL,
    current_rank INTEGER,
    rank_change INTEGER DEFAULT 0,
    bb_count DECIMAL(10,2),
    avg_stack_percentage DECIMAL(6,2),
    is_eliminated BOOLEAN DEFAULT FALSE,
    eliminated_at TIMESTAMPTZ,
    final_rank INTEGER,
    payout_received DECIMAL(12,2),
    entry_count INTEGER DEFAULT 1,
    registration_time TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_id, tournament_id)
);

-- 013: player_stats
CREATE TABLE IF NOT EXISTS player_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES player_instances(id) ON DELETE CASCADE,
    hands_played INTEGER DEFAULT 0,
    hands_won INTEGER DEFAULT 0,
    vpip DECIMAL(5,2) DEFAULT 0,
    pfr DECIMAL(5,2) DEFAULT 0,
    aggression_factor DECIMAL(5,2),
    showdown_win_rate DECIMAL(5,2),
    wtsd DECIMAL(5,2),
    three_bet_percentage DECIMAL(5,2),
    fold_to_three_bet DECIMAL(5,2),
    c_bet_percentage DECIMAL(5,2),
    all_in_count INTEGER DEFAULT 0,
    all_in_won INTEGER DEFAULT 0,
    last_calculated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_instance_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_players_master_name ON players_master(name);
CREATE INDEX IF NOT EXISTS idx_players_master_nationality ON players_master(nationality);
CREATE INDEX IF NOT EXISTS idx_players_master_bracelets ON players_master(wsop_bracelets DESC);
CREATE INDEX IF NOT EXISTS idx_feature_tables_tournament ON feature_tables(tournament_id);
CREATE INDEX IF NOT EXISTS idx_feature_tables_active ON feature_tables(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_player_instances_player ON player_instances(player_id);
CREATE INDEX IF NOT EXISTS idx_player_instances_tournament ON player_instances(tournament_id);
CREATE INDEX IF NOT EXISTS idx_player_instances_chips ON player_instances(chips DESC);
CREATE INDEX IF NOT EXISTS idx_player_instances_rank ON player_instances(current_rank);
CREATE INDEX IF NOT EXISTS idx_player_stats_instance ON player_stats(player_instance_id);
