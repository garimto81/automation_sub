-- ============================================================
-- Migration: 001_create_caption_tables.sql
-- Description: PRD-0003 자막 시스템 기본 테이블 생성 (13개)
-- Author: Claude Code
-- Date: 2026-01-06
-- PRD: PRD-0003 Caption Workflow
-- ============================================================

BEGIN;

-- ============================================================
-- 1. Core Reference Tables
-- ============================================================

-- 1.1 venues - 장소 정보
CREATE TABLE IF NOT EXISTS venues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    country CHAR(2),  -- ISO 3166-1 alpha-2
    address TEXT,
    drone_shot_url TEXT,
    photo_urls JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.2 events - 이벤트 정보
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    event_code VARCHAR(50) UNIQUE NOT NULL,  -- 'WSOP_2026_LV', 'WSOP_2025_SC_CYPRUS'
    venue_id UUID REFERENCES venues(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'scheduled',  -- 'scheduled', 'running', 'completed'
    logo_url TEXT,
    sponsor_logos JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.3 commentators - 코멘테이터 정보
CREATE TABLE IF NOT EXISTS commentators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    credentials TEXT,
    biography TEXT,
    social_links JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.4 schedules - 방송 스케줄
CREATE TABLE IF NOT EXISTS schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    time_start TIME NOT NULL,
    time_end TIME,
    event_name VARCHAR(255) NOT NULL,
    channel VARCHAR(100),
    is_live BOOLEAN DEFAULT FALSE,
    is_current BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. Tournament Tables
-- ============================================================

-- 2.1 tournaments - 토너먼트 정보
CREATE TABLE IF NOT EXISTS tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    buy_in DECIMAL(10,2) NOT NULL,
    starting_chips INTEGER NOT NULL,
    current_level INTEGER DEFAULT 1,
    current_day INTEGER DEFAULT 1,  -- Day 1, 2, 3, Final

    -- 참가자 정보
    registered_players INTEGER DEFAULT 0,
    remaining_players INTEGER DEFAULT 0,

    -- 상금 정보
    prize_pool DECIMAL(15,2) DEFAULT 0,
    bubble_line INTEGER,
    is_itm BOOLEAN DEFAULT FALSE,

    -- 등록 상태
    is_registration_open BOOLEAN DEFAULT TRUE,
    registration_closes_at TIMESTAMP,

    -- 평균 스택
    avg_stack INTEGER,

    status VARCHAR(20) DEFAULT 'scheduled',  -- 'scheduled', 'running', 'paused', 'completed'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.2 blind_levels - 블라인드 레벨
CREATE TABLE IF NOT EXISTS blind_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    level_number INTEGER NOT NULL,
    small_blind INTEGER NOT NULL,
    big_blind INTEGER NOT NULL,
    ante INTEGER DEFAULT 0,
    big_blind_ante INTEGER DEFAULT 0,
    duration_minutes INTEGER NOT NULL,
    is_break BOOLEAN DEFAULT FALSE,
    break_duration_minutes INTEGER,
    is_current BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMP,
    ends_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(tournament_id, level_number)
);

-- 2.3 payouts - 상금 구조
CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    place_start INTEGER NOT NULL,
    place_end INTEGER NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    percentage DECIMAL(5,2),
    is_current_bubble BOOLEAN DEFAULT FALSE,
    is_reached BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(tournament_id, place_start, place_end)
);

-- ============================================================
-- 3. Player Tables
-- ============================================================

-- 3.1 players - 플레이어 정보
CREATE TABLE IF NOT EXISTS players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 기본 정보
    name VARCHAR(255) NOT NULL,
    nationality CHAR(2) NOT NULL,  -- ISO 3166-1 alpha-2
    photo_url TEXT,

    -- 칩/좌석 정보
    chips INTEGER NOT NULL DEFAULT 0,
    seat_number INTEGER,  -- 1-10
    table_number INTEGER,

    -- 피처 테이블 여부
    is_feature_table BOOLEAN DEFAULT FALSE,

    -- 탈락 정보
    is_eliminated BOOLEAN DEFAULT FALSE,
    eliminated_at TIMESTAMP,
    final_rank INTEGER,
    payout_received DECIMAL(12,2),

    -- 순위 정보 (실시간 계산)
    current_rank INTEGER,
    rank_change INTEGER DEFAULT 0,
    bb_count DECIMAL(10,2),
    avg_stack_percentage DECIMAL(6,2),

    registration_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3.2 player_profiles - 플레이어 프로필 상세
CREATE TABLE IF NOT EXISTS player_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID UNIQUE NOT NULL REFERENCES players(id) ON DELETE CASCADE,

    -- 외부 ID
    hendon_mob_id VARCHAR(50),
    gpi_id VARCHAR(50),

    -- WSOP 성적
    wsop_bracelets INTEGER DEFAULT 0,
    wsop_rings INTEGER DEFAULT 0,
    wsop_final_tables INTEGER DEFAULT 0,

    -- 전체 성적
    total_earnings DECIMAL(15,2) DEFAULT 0,
    final_tables INTEGER DEFAULT 0,

    -- 프로필 정보
    long_name VARCHAR(255),  -- GFX LongName
    biography TEXT,
    notable_wins JSONB DEFAULT '[]',
    hometown VARCHAR(255),
    age INTEGER,
    profession VARCHAR(255),

    -- 소셜 링크
    social_links JSONB DEFAULT '{}',

    -- 키플레이어 태그
    is_key_player BOOLEAN DEFAULT FALSE,
    key_player_reason TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3.3 player_stats - 플레이어 통계
CREATE TABLE IF NOT EXISTS player_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 핸드 통계
    hands_played INTEGER DEFAULT 0,
    hands_won INTEGER DEFAULT 0,

    -- VPIP/PFR
    vpip DECIMAL(5,2) DEFAULT 0,
    pfr DECIMAL(5,2) DEFAULT 0,

    -- 고급 통계
    aggression_factor DECIMAL(5,2),
    showdown_win_rate DECIMAL(5,2),
    three_bet_percentage DECIMAL(5,2),
    fold_to_three_bet DECIMAL(5,2),
    c_bet_percentage DECIMAL(5,2),

    -- All-in 통계
    all_in_count INTEGER DEFAULT 0,
    all_in_won INTEGER DEFAULT 0,

    last_calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(player_id, tournament_id)
);

-- 3.4 chip_history - 칩 변동 히스토리
CREATE TABLE IF NOT EXISTS chip_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 핸드/레벨 정보
    hand_number INTEGER NOT NULL,
    level_number INTEGER NOT NULL,

    -- 칩 정보
    chips INTEGER NOT NULL,
    chips_change INTEGER DEFAULT 0,

    -- 계산값
    bb_count DECIMAL(10,2),
    avg_stack_percentage DECIMAL(6,2),

    -- 데이터 소스
    source VARCHAR(20) DEFAULT 'rfid',  -- 'rfid', 'manual', 'csv', 'gfx'

    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 4. Graphics Queue
-- ============================================================

-- 4.1 graphics_queue - 그래픽 큐
CREATE TABLE IF NOT EXISTS graphics_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,

    -- 그래픽 정보
    graphic_type VARCHAR(50) NOT NULL,
    trigger_event VARCHAR(50) NOT NULL,

    -- 데이터 페이로드
    payload JSONB NOT NULL DEFAULT '{}',

    -- 우선순위
    priority INTEGER DEFAULT 5,

    -- 상태
    status VARCHAR(20) DEFAULT 'pending',
    error_message TEXT,

    -- 타임스탬프
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rendered_at TIMESTAMP,
    displayed_at TIMESTAMP,
    dismissed_at TIMESTAMP
);

-- ============================================================
-- 5. Indexes (Core Tables)
-- ============================================================

-- events
CREATE INDEX IF NOT EXISTS idx_events_code ON events(event_code);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);

-- schedules
CREATE INDEX IF NOT EXISTS idx_schedules_event ON schedules(event_id);
CREATE INDEX IF NOT EXISTS idx_schedules_date ON schedules(date);
CREATE INDEX IF NOT EXISTS idx_schedules_current ON schedules(is_current) WHERE is_current = TRUE;

-- tournaments
CREATE INDEX IF NOT EXISTS idx_tournaments_event ON tournaments(event_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_status ON tournaments(status);
CREATE INDEX IF NOT EXISTS idx_tournaments_day ON tournaments(current_day);

-- blind_levels
CREATE INDEX IF NOT EXISTS idx_blinds_tournament ON blind_levels(tournament_id);
CREATE INDEX IF NOT EXISTS idx_blinds_level ON blind_levels(level_number);
CREATE INDEX IF NOT EXISTS idx_blinds_current ON blind_levels(is_current) WHERE is_current = TRUE;

-- payouts
CREATE INDEX IF NOT EXISTS idx_payouts_tournament ON payouts(tournament_id);
CREATE INDEX IF NOT EXISTS idx_payouts_place ON payouts(place_start, place_end);
CREATE INDEX IF NOT EXISTS idx_payouts_bubble ON payouts(is_current_bubble) WHERE is_current_bubble = TRUE;

-- players
CREATE INDEX IF NOT EXISTS idx_players_tournament ON players(tournament_id);
CREATE INDEX IF NOT EXISTS idx_players_chips ON players(chips DESC);
CREATE INDEX IF NOT EXISTS idx_players_table ON players(table_number, seat_number);
CREATE INDEX IF NOT EXISTS idx_players_feature ON players(is_feature_table) WHERE is_feature_table = TRUE;
CREATE INDEX IF NOT EXISTS idx_players_eliminated ON players(is_eliminated);
CREATE INDEX IF NOT EXISTS idx_players_rank ON players(current_rank);

-- player_profiles
CREATE INDEX IF NOT EXISTS idx_profiles_hendon ON player_profiles(hendon_mob_id);
CREATE INDEX IF NOT EXISTS idx_profiles_bracelets ON player_profiles(wsop_bracelets DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_earnings ON player_profiles(total_earnings DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_key_player ON player_profiles(is_key_player) WHERE is_key_player = TRUE;

-- player_stats
CREATE INDEX IF NOT EXISTS idx_stats_player ON player_stats(player_id);
CREATE INDEX IF NOT EXISTS idx_stats_vpip ON player_stats(vpip);
CREATE INDEX IF NOT EXISTS idx_stats_pfr ON player_stats(pfr);

-- chip_history
CREATE INDEX IF NOT EXISTS idx_chip_history_player ON chip_history(player_id);
CREATE INDEX IF NOT EXISTS idx_chip_history_tournament ON chip_history(tournament_id);
CREATE INDEX IF NOT EXISTS idx_chip_history_hand ON chip_history(hand_number DESC);
CREATE INDEX IF NOT EXISTS idx_chip_history_timestamp ON chip_history(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_chip_history_player_recent ON chip_history(player_id, hand_number DESC);

-- graphics_queue
CREATE INDEX IF NOT EXISTS idx_queue_tournament ON graphics_queue(tournament_id);
CREATE INDEX IF NOT EXISTS idx_queue_status ON graphics_queue(status);
CREATE INDEX IF NOT EXISTS idx_queue_priority ON graphics_queue(priority);
CREATE INDEX IF NOT EXISTS idx_queue_pending ON graphics_queue(status, priority, created_at) WHERE status = 'pending';

COMMIT;

-- ============================================================
-- Rollback Script (if needed)
-- ============================================================
-- DROP TABLE IF EXISTS graphics_queue CASCADE;
-- DROP TABLE IF EXISTS chip_history CASCADE;
-- DROP TABLE IF EXISTS player_stats CASCADE;
-- DROP TABLE IF EXISTS player_profiles CASCADE;
-- DROP TABLE IF EXISTS players CASCADE;
-- DROP TABLE IF EXISTS payouts CASCADE;
-- DROP TABLE IF EXISTS blind_levels CASCADE;
-- DROP TABLE IF EXISTS tournaments CASCADE;
-- DROP TABLE IF EXISTS schedules CASCADE;
-- DROP TABLE IF EXISTS commentators CASCADE;
-- DROP TABLE IF EXISTS events CASCADE;
-- DROP TABLE IF EXISTS venues CASCADE;
