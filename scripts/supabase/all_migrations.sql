-- ============================================================
-- Supabase 통합 DB 스키마 - ALL MIGRATIONS
-- Generated from 28 migration files
-- ============================================================


-- ============================================================
-- FILE: 001_create_venues.sql
-- ============================================================

-- ============================================================
-- Migration: 001_create_venues.sql
-- Description: Supabase 통합 스키마 - venues 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- venues - 장소 정보
CREATE TABLE IF NOT EXISTS venues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    country CHAR(2),  -- ISO 3166-1 alpha-2
    address TEXT,
    drone_shot_url TEXT,
    photo_urls JSONB DEFAULT '[]',
    timezone VARCHAR(50) DEFAULT 'UTC',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_venues_name ON venues(name);
CREATE INDEX IF NOT EXISTS idx_venues_country ON venues(country);

-- Comment
COMMENT ON TABLE venues IS '이벤트 장소 정보 (WSOP Las Vegas, WSOP Europe 등)';



-- ============================================================
-- FILE: 002_create_events.sql
-- ============================================================

-- ============================================================
-- Migration: 002_create_events.sql
-- Description: Supabase 통합 스키마 - events 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- events - 이벤트 정보
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    event_code VARCHAR(50) UNIQUE NOT NULL,  -- 'WSOP_2026_LV', 'WSOP_2025_SC_CYPRUS'
    venue_id UUID REFERENCES venues(id) ON DELETE SET NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'scheduled',  -- 'scheduled', 'running', 'completed'
    logo_url TEXT,
    sponsor_logos JSONB DEFAULT '[]',
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_events_code ON events(event_code);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_venue ON events(venue_id);
CREATE INDEX IF NOT EXISTS idx_events_dates ON events(start_date, end_date);

-- Comment
COMMENT ON TABLE events IS 'WSOP 이벤트 정보 (연간 시리즈 단위)';



-- ============================================================
-- FILE: 003_create_tournaments.sql
-- ============================================================

-- ============================================================
-- Migration: 003_create_tournaments.sql
-- Description: Supabase 통합 스키마 - tournaments 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- tournaments - 토너먼트 정보
CREATE TABLE IF NOT EXISTS tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    tournament_number INTEGER,  -- WSOP Event #1, #2, etc.
    buy_in DECIMAL(10,2) NOT NULL,
    starting_chips INTEGER NOT NULL,
    current_level INTEGER DEFAULT 1,
    current_day INTEGER DEFAULT 1,  -- Day 1, 2, 3, Final

    -- 참가자 정보
    registered_players INTEGER DEFAULT 0,
    remaining_players INTEGER DEFAULT 0,
    unique_players INTEGER DEFAULT 0,  -- Re-entry 제외

    -- 상금 정보
    prize_pool DECIMAL(15,2) DEFAULT 0,
    bubble_line INTEGER,
    is_itm BOOLEAN DEFAULT FALSE,

    -- 등록 상태
    is_registration_open BOOLEAN DEFAULT TRUE,
    registration_closes_at TIMESTAMPTZ,

    -- 평균 스택
    avg_stack INTEGER,

    -- 상태
    status VARCHAR(20) DEFAULT 'scheduled',  -- 'scheduled', 'running', 'paused', 'completed'

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_tournaments_event ON tournaments(event_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_status ON tournaments(status);
CREATE INDEX IF NOT EXISTS idx_tournaments_day ON tournaments(current_day);
CREATE INDEX IF NOT EXISTS idx_tournaments_number ON tournaments(tournament_number);

-- Comment
COMMENT ON TABLE tournaments IS '개별 토너먼트 정보 (Main Event, $1500 NLH 등)';



-- ============================================================
-- FILE: 004_create_blind_levels.sql
-- ============================================================

-- ============================================================
-- Migration: 004_create_blind_levels.sql
-- Description: Supabase 통합 스키마 - blind_levels 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- blind_levels - 블라인드 레벨
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
    started_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tournament_id, level_number)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_blinds_tournament ON blind_levels(tournament_id);
CREATE INDEX IF NOT EXISTS idx_blinds_level ON blind_levels(level_number);
CREATE INDEX IF NOT EXISTS idx_blinds_current ON blind_levels(tournament_id) WHERE is_current = TRUE;

-- Comment
COMMENT ON TABLE blind_levels IS '토너먼트 블라인드 구조';



-- ============================================================
-- FILE: 005_create_payouts.sql
-- ============================================================

-- ============================================================
-- Migration: 005_create_payouts.sql
-- Description: Supabase 통합 스키마 - payouts 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- payouts - 상금 구조
CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    place_start INTEGER NOT NULL,
    place_end INTEGER NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    percentage DECIMAL(5,2),
    is_current_bubble BOOLEAN DEFAULT FALSE,
    is_reached BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tournament_id, place_start, place_end)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_payouts_tournament ON payouts(tournament_id);
CREATE INDEX IF NOT EXISTS idx_payouts_place ON payouts(place_start, place_end);
CREATE INDEX IF NOT EXISTS idx_payouts_bubble ON payouts(tournament_id) WHERE is_current_bubble = TRUE;

-- Comment
COMMENT ON TABLE payouts IS '토너먼트 상금 구조 (place_start:end 범위)';



-- ============================================================
-- FILE: 006_create_commentators.sql
-- ============================================================

-- ============================================================
-- Migration: 006_create_commentators.sql
-- Description: Supabase 통합 스키마 - commentators 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- commentators - 코멘테이터 정보
CREATE TABLE IF NOT EXISTS commentators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    credentials TEXT,  -- "3x WSOP Bracelet Winner"
    biography TEXT,
    social_links JSONB DEFAULT '{}',  -- {"twitter": "@...", "instagram": "..."}
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_commentators_name ON commentators(name);
CREATE INDEX IF NOT EXISTS idx_commentators_active ON commentators(is_active) WHERE is_active = TRUE;

-- Comment
COMMENT ON TABLE commentators IS '방송 코멘테이터/해설자 정보';



-- ============================================================
-- FILE: 007_create_schedules.sql
-- ============================================================

-- ============================================================
-- Migration: 007_create_schedules.sql
-- Description: Supabase 통합 스키마 - schedules 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 1 - Core Reference
-- ============================================================

-- schedules - 방송 스케줄
CREATE TABLE IF NOT EXISTS schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    time_start TIME NOT NULL,
    time_end TIME,
    title VARCHAR(255) NOT NULL,
    channel VARCHAR(100),  -- "PokerGO", "CBS Sports"
    is_live BOOLEAN DEFAULT FALSE,
    is_current BOOLEAN DEFAULT FALSE,
    stream_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_schedules_event ON schedules(event_id);
CREATE INDEX IF NOT EXISTS idx_schedules_tournament ON schedules(tournament_id);
CREATE INDEX IF NOT EXISTS idx_schedules_date ON schedules(date);
CREATE INDEX IF NOT EXISTS idx_schedules_current ON schedules(is_current) WHERE is_current = TRUE;
CREATE INDEX IF NOT EXISTS idx_schedules_live ON schedules(is_live) WHERE is_live = TRUE;

-- Comment
COMMENT ON TABLE schedules IS '방송 스케줄 (라이브/리플레이)';



-- ============================================================
-- FILE: 010_create_players_master.sql
-- ============================================================

-- ============================================================
-- Migration: 010_create_players_master.sql
-- Description: Supabase 통합 스키마 - players_master 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 2 - Player System
-- Note: 기존 players 테이블을 마스터/인스턴스로 분리
-- ============================================================

-- players_master - 플레이어 마스터 (중앙 집중)
-- 동일 플레이어가 여러 토너먼트에 참가해도 마스터 데이터는 하나
CREATE TABLE IF NOT EXISTS players_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 기본 정보
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),  -- 방송용 표시 이름
    nationality CHAR(2),  -- ISO 3166-1 alpha-2
    photo_url TEXT,

    -- 외부 ID (중복 방지용)
    hendon_mob_id VARCHAR(50) UNIQUE,
    gpi_id VARCHAR(50) UNIQUE,

    -- WSOP 성적 (누적)
    wsop_bracelets INTEGER DEFAULT 0,
    wsop_rings INTEGER DEFAULT 0,
    wsop_final_tables INTEGER DEFAULT 0,

    -- 전체 성적 (누적)
    total_earnings DECIMAL(15,2) DEFAULT 0,
    total_final_tables INTEGER DEFAULT 0,

    -- 프로필 정보 (player_profiles 병합)
    biography TEXT,
    notable_wins JSONB DEFAULT '[]',
    hometown VARCHAR(255),
    profession VARCHAR(255),

    -- 소셜 링크
    social_links JSONB DEFAULT '{}',

    -- 키플레이어 태그
    is_key_player BOOLEAN DEFAULT FALSE,
    key_player_reason TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 이름 기반 자동 매칭을 위한 UNIQUE (대소문자 무시)
    CONSTRAINT players_master_name_unique UNIQUE (name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_players_master_name ON players_master(name);
CREATE INDEX IF NOT EXISTS idx_players_master_nationality ON players_master(nationality);
CREATE INDEX IF NOT EXISTS idx_players_master_hendon ON players_master(hendon_mob_id);
CREATE INDEX IF NOT EXISTS idx_players_master_gpi ON players_master(gpi_id);
CREATE INDEX IF NOT EXISTS idx_players_master_bracelets ON players_master(wsop_bracelets DESC);
CREATE INDEX IF NOT EXISTS idx_players_master_earnings ON players_master(total_earnings DESC);
CREATE INDEX IF NOT EXISTS idx_players_master_key ON players_master(is_key_player) WHERE is_key_player = TRUE;

-- Comment
COMMENT ON TABLE players_master IS '플레이어 마스터 테이블 - 토너먼트 독립적인 영구 데이터';
COMMENT ON COLUMN players_master.name IS '플레이어 이름 (GFX Name 매칭 키)';
COMMENT ON COLUMN players_master.display_name IS '방송 표시용 이름 (GFX LongName)';



-- ============================================================
-- FILE: 011_create_feature_tables.sql
-- ============================================================

-- ============================================================
-- Migration: 011_create_feature_tables.sql
-- Description: Supabase 통합 스키마 - feature_tables 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 2 - Player System
-- ============================================================

-- feature_tables - 피처 테이블 관리
CREATE TABLE IF NOT EXISTS feature_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 테이블 정보
    table_number INTEGER NOT NULL,
    table_name VARCHAR(100),  -- "Amazon Room Table 1"

    -- RFID 연동
    rfid_device_id VARCHAR(100),
    gfx_table_id VARCHAR(100),  -- pokerGFX 테이블 ID

    -- 상태
    is_active BOOLEAN DEFAULT TRUE,
    is_streaming BOOLEAN DEFAULT FALSE,

    -- 카메라/방송 설정
    camera_config JSONB DEFAULT '{}',

    -- 시간 추적
    activated_at TIMESTAMPTZ,
    deactivated_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tournament_id, table_number)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_feature_tables_tournament ON feature_tables(tournament_id);
CREATE INDEX IF NOT EXISTS idx_feature_tables_active ON feature_tables(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_feature_tables_streaming ON feature_tables(is_streaming) WHERE is_streaming = TRUE;
CREATE INDEX IF NOT EXISTS idx_feature_tables_rfid ON feature_tables(rfid_device_id);

-- Comment
COMMENT ON TABLE feature_tables IS '피처 테이블 (RFID 연동, 방송 대상)';



-- ============================================================
-- FILE: 012_create_player_instances.sql
-- ============================================================

-- ============================================================
-- Migration: 012_create_player_instances.sql
-- Description: Supabase 통합 스키마 - player_instances 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 2 - Player System
-- Note: 토너먼트별 플레이어 상태 (기존 players 대체)
-- ============================================================

-- player_instances - 토너먼트별 플레이어 인스턴스
-- 동일 플레이어가 여러 토너먼트에 참가하면 인스턴스가 각각 생성됨
CREATE TABLE IF NOT EXISTS player_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players_master(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 현재 상태
    chips BIGINT NOT NULL DEFAULT 0,
    seat_number INTEGER,  -- 1-10
    table_number INTEGER,
    feature_table_id UUID REFERENCES feature_tables(id) ON DELETE SET NULL,

    -- 순위 정보 (실시간 계산)
    current_rank INTEGER,
    rank_change INTEGER DEFAULT 0,
    bb_count DECIMAL(10,2),
    avg_stack_percentage DECIMAL(6,2),

    -- 탈락 정보
    is_eliminated BOOLEAN DEFAULT FALSE,
    eliminated_at TIMESTAMPTZ,
    final_rank INTEGER,
    payout_received DECIMAL(12,2),

    -- 등록 정보
    entry_count INTEGER DEFAULT 1,  -- Re-entry 횟수
    registration_time TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 동일 토너먼트에 동일 플레이어는 하나의 인스턴스만
    UNIQUE(player_id, tournament_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_player_instances_player ON player_instances(player_id);
CREATE INDEX IF NOT EXISTS idx_player_instances_tournament ON player_instances(tournament_id);
CREATE INDEX IF NOT EXISTS idx_player_instances_chips ON player_instances(chips DESC);
CREATE INDEX IF NOT EXISTS idx_player_instances_rank ON player_instances(current_rank);
CREATE INDEX IF NOT EXISTS idx_player_instances_table ON player_instances(table_number, seat_number);
CREATE INDEX IF NOT EXISTS idx_player_instances_feature ON player_instances(feature_table_id) WHERE feature_table_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_player_instances_eliminated ON player_instances(is_eliminated);
CREATE INDEX IF NOT EXISTS idx_player_instances_active ON player_instances(tournament_id) WHERE is_eliminated = FALSE;

-- Comment
COMMENT ON TABLE player_instances IS '토너먼트별 플레이어 인스턴스 - 칩, 좌석, 순위 등 실시간 상태';
COMMENT ON COLUMN player_instances.player_id IS 'players_master FK - 마스터 데이터 참조';
COMMENT ON COLUMN player_instances.chips IS '현재 칩 수량 (BIGINT for large stacks)';



-- ============================================================
-- FILE: 013_create_player_stats.sql
-- ============================================================

-- ============================================================
-- Migration: 013_create_player_stats.sql
-- Description: Supabase 통합 스키마 - player_stats 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 2 - Player System
-- ============================================================

-- player_stats - 플레이어 통계 (토너먼트별)
CREATE TABLE IF NOT EXISTS player_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES player_instances(id) ON DELETE CASCADE,

    -- 핸드 통계
    hands_played INTEGER DEFAULT 0,
    hands_won INTEGER DEFAULT 0,

    -- VPIP/PFR (GFX에서 직접 제공)
    vpip DECIMAL(5,2) DEFAULT 0,
    pfr DECIMAL(5,2) DEFAULT 0,

    -- 고급 통계
    aggression_factor DECIMAL(5,2),
    showdown_win_rate DECIMAL(5,2),
    wtsd DECIMAL(5,2),  -- Went To ShowDown
    three_bet_percentage DECIMAL(5,2),
    fold_to_three_bet DECIMAL(5,2),
    c_bet_percentage DECIMAL(5,2),

    -- All-in 통계
    all_in_count INTEGER DEFAULT 0,
    all_in_won INTEGER DEFAULT 0,

    -- 마지막 계산 시간
    last_calculated_at TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(player_instance_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_player_stats_instance ON player_stats(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_player_stats_vpip ON player_stats(vpip);
CREATE INDEX IF NOT EXISTS idx_player_stats_pfr ON player_stats(pfr);
CREATE INDEX IF NOT EXISTS idx_player_stats_hands ON player_stats(hands_played DESC);

-- Comment
COMMENT ON TABLE player_stats IS '토너먼트별 플레이어 통계 (VPIP, PFR, AF 등)';
COMMENT ON COLUMN player_stats.vpip IS 'Voluntarily Put In Pot - 자발적 팟 참여율 (%)';
COMMENT ON COLUMN player_stats.pfr IS 'Pre-Flop Raise - 프리플랍 레이즈율 (%)';



-- ============================================================
-- FILE: 020_create_gfx_sessions.sql
-- ============================================================

-- ============================================================
-- Migration: 020_create_gfx_sessions.sql
-- Description: Supabase 통합 스키마 - gfx_sessions 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- ============================================================

-- gfx_sessions - pokerGFX 세션 데이터
CREATE TABLE IF NOT EXISTS gfx_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    feature_table_id UUID REFERENCES feature_tables(id) ON DELETE SET NULL,

    -- GFX 고유 ID (Windows 파일 시간 형식)
    gfx_id BIGINT UNIQUE NOT NULL,

    -- GFX 메타데이터
    event_title VARCHAR(255),
    table_type VARCHAR(50) NOT NULL,  -- 'FEATURE_TABLE', 'OUTER_TABLE', 'FINAL_TABLE'
    software_version VARCHAR(50),  -- 'PokerGFX 3.2'

    -- 페이아웃 배열
    payouts JSONB DEFAULT '[]',

    -- 상태
    status VARCHAR(20) DEFAULT 'active',  -- 'active', 'completed', 'error'
    total_hands INTEGER DEFAULT 0,

    -- GFX 시간
    created_at_gfx TIMESTAMPTZ,  -- GFX CreatedDateTimeUTC

    -- 파일 정보
    source_file VARCHAR(500),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_gfx_id ON gfx_sessions(gfx_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_tournament ON gfx_sessions(tournament_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_feature ON gfx_sessions(feature_table_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_status ON gfx_sessions(status);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_type ON gfx_sessions(table_type);

-- Comment
COMMENT ON TABLE gfx_sessions IS 'pokerGFX 세션 데이터 (JSON 파일 단위)';
COMMENT ON COLUMN gfx_sessions.gfx_id IS 'pokerGFX ID (Windows 파일 시간 형식, 100ns 단위)';



-- ============================================================
-- FILE: 021_create_hands.sql
-- ============================================================

-- ============================================================
-- Migration: 021_create_hands.sql
-- Description: Supabase 통합 스키마 - hands 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- ============================================================

-- hands - 핸드 메타정보
CREATE TABLE IF NOT EXISTS hands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gfx_session_id UUID REFERENCES gfx_sessions(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,

    -- 핸드 식별
    hand_number INTEGER NOT NULL,
    table_number INTEGER,

    -- 게임 정보
    game_variant VARCHAR(20) NOT NULL DEFAULT 'HOLDEM',  -- 'HOLDEM', 'OMAHA', 'STUD'
    game_class VARCHAR(20) NOT NULL DEFAULT 'FLOP',  -- 'FLOP', 'DRAW', 'STUD'
    bet_structure VARCHAR(20) NOT NULL DEFAULT 'NOLIMIT',  -- 'NOLIMIT', 'POTLIMIT', 'LIMIT'

    -- 블라인드/버튼 정보
    button_seat INTEGER,
    small_blind_seat INTEGER,
    big_blind_seat INTEGER,
    small_blind_amount DECIMAL(12,2),
    big_blind_amount DECIMAL(12,2),
    ante_amount DECIMAL(12,2) DEFAULT 0,
    ante_type VARCHAR(30),  -- 'BB_ANTE_BB1ST', 'ANTE_ALL'
    level_number INTEGER,

    -- 팟/보드 정보
    pot_size DECIMAL(12,2),
    num_boards INTEGER DEFAULT 1,
    run_it_num_times INTEGER DEFAULT 1,

    -- 승자 정보
    winner_id UUID REFERENCES players_master(id) ON DELETE SET NULL,
    winning_hand VARCHAR(50),  -- 'Full House', 'Flush' 등

    -- 등급 (automation_feature_table 통합)
    grade CHAR(1),  -- 'A', 'B', 'C', 'D'
    is_premium BOOLEAN DEFAULT FALSE,  -- Grade A/B
    grade_factors JSONB DEFAULT '{}',  -- {"pot_size": true, "all_in": true, "premium_hand": false}

    -- 시간 정보
    duration INTERVAL,  -- GFX Duration (ISO 8601)
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hands_gfx_session ON hands(gfx_session_id);
CREATE INDEX IF NOT EXISTS idx_hands_tournament ON hands(tournament_id);
CREATE INDEX IF NOT EXISTS idx_hands_number ON hands(hand_number);
CREATE INDEX IF NOT EXISTS idx_hands_grade ON hands(grade) WHERE grade IN ('A', 'B');
CREATE INDEX IF NOT EXISTS idx_hands_premium ON hands(is_premium) WHERE is_premium = TRUE;
CREATE INDEX IF NOT EXISTS idx_hands_winner ON hands(winner_id);
CREATE INDEX IF NOT EXISTS idx_hands_started ON hands(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_hands_session_number ON hands(gfx_session_id, hand_number);

-- Comment
COMMENT ON TABLE hands IS '핸드 메타정보 (GFX Hand 객체 매핑)';
COMMENT ON COLUMN hands.grade IS '핸드 등급: A(최상), B(상), C(중), D(하)';



-- ============================================================
-- FILE: 022_create_hand_players.sql
-- ============================================================

-- ============================================================
-- Migration: 022_create_hand_players.sql
-- Description: Supabase 통합 스키마 - hand_players 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- ============================================================

-- hand_players - 핸드별 플레이어 상태
CREATE TABLE IF NOT EXISTS hand_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players_master(id) ON DELETE CASCADE,
    player_instance_id UUID REFERENCES player_instances(id) ON DELETE SET NULL,

    -- GFX 플레이어 정보
    seat_number INTEGER NOT NULL,  -- 1-10

    -- 스택 정보
    start_stack BIGINT NOT NULL,
    end_stack BIGINT NOT NULL,
    stack_delta BIGINT GENERATED ALWAYS AS (end_stack - start_stack) STORED,
    cumulative_winnings BIGINT DEFAULT 0,

    -- 홀 카드 (변환된 형식)
    hole_cards VARCHAR(10),  -- 'AsKh', 'TdTc' 등

    -- 플레이어 상태
    sitting_out BOOLEAN DEFAULT FALSE,
    is_winner BOOLEAN DEFAULT FALSE,

    -- GFX 통계 (핸드 시점)
    vpip_percent DECIMAL(5,2),
    pfr_percent DECIMAL(5,2),
    aggression_percent DECIMAL(5,2),
    wtsd_percent DECIMAL(5,2),

    -- 탈락 정보 (이 핸드에서 탈락 시)
    elimination_rank INTEGER,  -- -1: 미탈락, 1+: 탈락 순위

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(hand_id, seat_number)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hand_players_hand ON hand_players(hand_id);
CREATE INDEX IF NOT EXISTS idx_hand_players_player ON hand_players(player_id);
CREATE INDEX IF NOT EXISTS idx_hand_players_instance ON hand_players(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_hand_players_seat ON hand_players(seat_number);
CREATE INDEX IF NOT EXISTS idx_hand_players_winner ON hand_players(is_winner) WHERE is_winner = TRUE;
CREATE INDEX IF NOT EXISTS idx_hand_players_delta ON hand_players(stack_delta DESC);

-- Comment
COMMENT ON TABLE hand_players IS '핸드별 플레이어 상태 (GFX Player 객체 매핑)';
COMMENT ON COLUMN hand_players.hole_cards IS '홀 카드 (변환됨: as,kh → AsKh)';
COMMENT ON COLUMN hand_players.stack_delta IS '스택 변동 (자동 계산: end_stack - start_stack)';



-- ============================================================
-- FILE: 023_create_hand_actions.sql
-- ============================================================

-- ============================================================
-- Migration: 023_create_hand_actions.sql
-- Description: Supabase 통합 스키마 - hand_actions 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- ============================================================

-- hand_actions - 핸드 액션 로그
CREATE TABLE IF NOT EXISTS hand_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,
    player_id UUID REFERENCES players_master(id) ON DELETE SET NULL,

    -- 액션 순서
    action_order INTEGER NOT NULL,
    street VARCHAR(20) NOT NULL,  -- 'preflop', 'flop', 'turn', 'river', 'showdown'

    -- GFX Event 매핑
    action VARCHAR(20) NOT NULL,  -- 'fold', 'call', 'raise', 'check', 'bet', 'all-in', 'showdown'
    seat_number INTEGER,

    -- 베팅 정보
    bet_amount DECIMAL(12,2),
    pot_size_after DECIMAL(12,2),

    -- Run It Twice 지원
    board_num INTEGER DEFAULT 0,

    -- Draw 게임용
    num_cards_drawn INTEGER DEFAULT 0,

    -- 시간 (GFX DateTimeUTC - 보통 null)
    action_time TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hand_actions_hand ON hand_actions(hand_id);
CREATE INDEX IF NOT EXISTS idx_hand_actions_player ON hand_actions(player_id);
CREATE INDEX IF NOT EXISTS idx_hand_actions_order ON hand_actions(hand_id, action_order);
CREATE INDEX IF NOT EXISTS idx_hand_actions_street ON hand_actions(street);
CREATE INDEX IF NOT EXISTS idx_hand_actions_action ON hand_actions(action);
CREATE INDEX IF NOT EXISTS idx_hand_actions_allin ON hand_actions(hand_id) WHERE action = 'all-in';

-- Comment
COMMENT ON TABLE hand_actions IS '핸드 액션 로그 (GFX Event 객체 매핑)';
COMMENT ON COLUMN hand_actions.street IS '베팅 라운드: preflop, flop, turn, river, showdown';
COMMENT ON COLUMN hand_actions.action IS 'GFX EventType 매핑: fold, call, raise, check, bet, all-in';



-- ============================================================
-- FILE: 024_create_hand_cards.sql
-- ============================================================

-- ============================================================
-- Migration: 024_create_hand_cards.sql
-- Description: Supabase 통합 스키마 - hand_cards 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- Note: community_cards 대체, 홀카드+보드 통합
-- ============================================================

-- hand_cards - 핸드별 카드 (홀카드 + 커뮤니티 카드 통합)
CREATE TABLE IF NOT EXISTS hand_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,

    -- 카드 정보 (변환된 형식)
    card_rank CHAR(2) NOT NULL,  -- 'A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'
    card_suit CHAR(1) NOT NULL,  -- 'h', 'd', 'c', 's'

    -- 카드 타입/위치
    card_type VARCHAR(20) NOT NULL,  -- 'hole', 'flop', 'turn', 'river'
    seat_number INTEGER,  -- hole card인 경우만 좌석 번호
    card_order INTEGER,  -- 같은 타입 내 순서 (flop 1,2,3 등)

    -- Run It Twice 지원
    board_num INTEGER DEFAULT 0,

    -- GFX 원본 (디버깅용)
    gfx_card VARCHAR(10),  -- 'as', 'kh', '10d' 등

    -- 데이터 소스
    source VARCHAR(20) DEFAULT 'gfx',  -- 'gfx', 'manual', 'ai'

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hand_cards_hand ON hand_cards(hand_id);
CREATE INDEX IF NOT EXISTS idx_hand_cards_type ON hand_cards(card_type);
CREATE INDEX IF NOT EXISTS idx_hand_cards_seat ON hand_cards(seat_number) WHERE seat_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hand_cards_board ON hand_cards(board_num) WHERE board_num > 0;
CREATE INDEX IF NOT EXISTS idx_hand_cards_hand_type ON hand_cards(hand_id, card_type, card_order);

-- Comment
COMMENT ON TABLE hand_cards IS '핸드별 카드 (홀카드 + 커뮤니티 카드 통합)';
COMMENT ON COLUMN hand_cards.card_rank IS '카드 랭크: A, K, Q, J, T, 9-2';
COMMENT ON COLUMN hand_cards.card_suit IS '카드 수트: h(하트), d(다이아), c(클럽), s(스페이드)';
COMMENT ON COLUMN hand_cards.card_type IS '카드 타입: hole(홀카드), flop, turn, river';



-- ============================================================
-- FILE: 025_create_chip_flow.sql
-- ============================================================

-- ============================================================
-- Migration: 025_create_chip_flow.sql
-- Description: Supabase 통합 스키마 - chip_flow 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 3 - Hand System
-- Note: chip_history 대체, running_total 추가
-- ============================================================

-- chip_flow - 칩 흐름 추적 (시계열)
CREATE TABLE IF NOT EXISTS chip_flow (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES player_instances(id) ON DELETE CASCADE,
    hand_id UUID REFERENCES hands(id) ON DELETE SET NULL,

    -- 변동 정보
    delta BIGINT NOT NULL,  -- 변동량 (+/-)
    reason VARCHAR(50),  -- 'pot_win', 'blind', 'ante', 'elimination', 'rebuy', 'addon'
    running_total BIGINT NOT NULL,  -- 변동 후 총 칩

    -- 컨텍스트
    hand_number INTEGER,
    level_number INTEGER,

    -- 계산값
    bb_count DECIMAL(10,2),  -- 현재 BB 기준
    avg_stack_percentage DECIMAL(6,2),  -- 평균 스택 대비 %

    -- 데이터 소스
    source VARCHAR(20) DEFAULT 'gfx',  -- 'gfx', 'rfid', 'manual', 'csv'

    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_chip_flow_instance ON chip_flow(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_chip_flow_hand ON chip_flow(hand_id);
CREATE INDEX IF NOT EXISTS idx_chip_flow_timestamp ON chip_flow(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_chip_flow_hand_number ON chip_flow(hand_number DESC);
CREATE INDEX IF NOT EXISTS idx_chip_flow_reason ON chip_flow(reason);
CREATE INDEX IF NOT EXISTS idx_chip_flow_instance_recent ON chip_flow(player_instance_id, timestamp DESC);

-- Comment
COMMENT ON TABLE chip_flow IS '칩 흐름 시계열 데이터 (chip_history 대체)';
COMMENT ON COLUMN chip_flow.delta IS '칩 변동량 (+: 획득, -: 손실)';
COMMENT ON COLUMN chip_flow.running_total IS '변동 후 총 칩 (누적 합계)';
COMMENT ON COLUMN chip_flow.reason IS '변동 사유: pot_win, blind, ante, elimination, rebuy, addon';



-- ============================================================
-- FILE: 030_create_graphics_queue.sql
-- ============================================================

-- ============================================================
-- Migration: 030_create_graphics_queue.sql
-- Description: Supabase 통합 스키마 - graphics_queue 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 4 - Broadcast System
-- ============================================================

-- graphics_queue - 그래픽/자막 렌더링 큐
CREATE TABLE IF NOT EXISTS graphics_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    hand_id UUID REFERENCES hands(id) ON DELETE SET NULL,

    -- 그래픽 정보 (26개 자막 유형)
    graphic_type VARCHAR(50) NOT NULL,  -- 'tournament_leaderboard', 'chip_flow', 'elimination_banner' 등
    trigger_event VARCHAR(50) NOT NULL,  -- 'hand_complete', 'level_up', 'elimination' 등

    -- 데이터 페이로드 (자막별 구조)
    payload JSONB NOT NULL DEFAULT '{}',

    -- 우선순위 (1: 최고 ~ 10: 최저)
    priority INTEGER DEFAULT 5,

    -- 상태
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'rendering', 'rendered', 'displayed', 'dismissed', 'error'
    error_message TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    scheduled_at TIMESTAMPTZ,  -- 예약 표시 시간
    rendered_at TIMESTAMPTZ,
    displayed_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_queue_tournament ON graphics_queue(tournament_id);
CREATE INDEX IF NOT EXISTS idx_queue_hand ON graphics_queue(hand_id);
CREATE INDEX IF NOT EXISTS idx_queue_type ON graphics_queue(graphic_type);
CREATE INDEX IF NOT EXISTS idx_queue_status ON graphics_queue(status);
CREATE INDEX IF NOT EXISTS idx_queue_priority ON graphics_queue(priority);
CREATE INDEX IF NOT EXISTS idx_queue_pending ON graphics_queue(status, priority, created_at) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_queue_scheduled ON graphics_queue(scheduled_at) WHERE scheduled_at IS NOT NULL;

-- Comment
COMMENT ON TABLE graphics_queue IS '그래픽/자막 렌더링 큐 (26개 자막 유형)';
COMMENT ON COLUMN graphics_queue.graphic_type IS '자막 유형: tournament_leaderboard, chip_flow, elimination_banner 등';



-- ============================================================
-- FILE: 031_create_eliminations.sql
-- ============================================================

-- ============================================================
-- Migration: 031_create_eliminations.sql
-- Description: Supabase 통합 스키마 - eliminations 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 4 - Broadcast System
-- ============================================================

-- eliminations - 탈락 상세 정보
CREATE TABLE IF NOT EXISTS eliminations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES player_instances(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 탈락 핸드 정보
    elimination_hand_id UUID REFERENCES hands(id) ON DELETE SET NULL,
    hand_number INTEGER,

    -- 탈락 정보
    final_rank INTEGER NOT NULL,
    payout_received DECIMAL(12,2) DEFAULT 0,

    -- 승자 정보 (누가 탈락시켰는지)
    eliminated_by_id UUID REFERENCES players_master(id) ON DELETE SET NULL,

    -- 탈락 상황 상세
    final_hand VARCHAR(50),  -- "Pair of Aces"
    losing_hand VARCHAR(50),  -- "Pair of Kings"
    final_chips BIGINT DEFAULT 0,

    -- 시간
    eliminated_at TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_eliminations_instance ON eliminations(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_eliminations_tournament ON eliminations(tournament_id);
CREATE INDEX IF NOT EXISTS idx_eliminations_hand ON eliminations(elimination_hand_id);
CREATE INDEX IF NOT EXISTS idx_eliminations_rank ON eliminations(final_rank);
CREATE INDEX IF NOT EXISTS idx_eliminations_time ON eliminations(eliminated_at DESC);
CREATE INDEX IF NOT EXISTS idx_eliminations_eliminated_by ON eliminations(eliminated_by_id);

-- Comment
COMMENT ON TABLE eliminations IS '플레이어 탈락 상세 정보';
COMMENT ON COLUMN eliminations.eliminated_by_id IS '탈락시킨 플레이어 (승자)';



-- ============================================================
-- FILE: 032_create_soft_contents.sql
-- ============================================================

-- ============================================================
-- Migration: 032_create_soft_contents.sql
-- Description: Supabase 통합 스키마 - soft_contents 테이블
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 4 - Broadcast System
-- ============================================================

-- soft_contents - 소프트 콘텐츠 큐 (Player Intro, Interview 등)
CREATE TABLE IF NOT EXISTS soft_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    player_id UUID REFERENCES players_master(id) ON DELETE SET NULL,

    -- 콘텐츠 타입
    content_type VARCHAR(50) NOT NULL,  -- 'player_intro', 'hand_highlight', 'interview', 'special_moment'

    -- 콘텐츠 정보
    title VARCHAR(255),
    description TEXT,
    payload JSONB DEFAULT '{}',

    -- 미디어
    media_url TEXT,
    thumbnail_url TEXT,
    duration_seconds INTEGER,

    -- 스케줄
    scheduled_at TIMESTAMPTZ,
    displayed_at TIMESTAMPTZ,

    -- 우선순위
    priority INTEGER DEFAULT 5,

    -- 상태
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'displayed', 'skipped'

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_soft_contents_tournament ON soft_contents(tournament_id);
CREATE INDEX IF NOT EXISTS idx_soft_contents_player ON soft_contents(player_id);
CREATE INDEX IF NOT EXISTS idx_soft_contents_type ON soft_contents(content_type);
CREATE INDEX IF NOT EXISTS idx_soft_contents_status ON soft_contents(status);
CREATE INDEX IF NOT EXISTS idx_soft_contents_scheduled ON soft_contents(scheduled_at) WHERE scheduled_at IS NOT NULL;

-- Comment
COMMENT ON TABLE soft_contents IS '소프트 콘텐츠 (Player Intro, Interview, Hand Highlight 등)';



-- ============================================================
-- FILE: 033_create_clip_markers.sql
-- ============================================================

-- ============================================================
-- Migration: 033_create_clip_markers.sql
-- Description: Supabase 통합 스키마 - clip_markers 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 4 - Broadcast System
-- Note: automation_feature_table 통합 - 편집 마커
-- ============================================================

-- clip_markers - 편집 마커 (클립 추출용)
CREATE TABLE IF NOT EXISTS clip_markers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID REFERENCES hands(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,

    -- 마커 정보
    marker_type VARCHAR(50) NOT NULL,  -- 'premium_hand', 'all_in', 'elimination', 'big_pot', 'bluff'
    title VARCHAR(255),
    description TEXT,

    -- 타임코드 (녹화 기준)
    start_timecode VARCHAR(20),  -- "01:23:45:12" (HH:MM:SS:FF)
    end_timecode VARCHAR(20),
    duration_seconds INTEGER,

    -- 핸드 등급
    grade CHAR(1),  -- 'A', 'B', 'C', 'D'

    -- 관련 플레이어
    player_ids JSONB DEFAULT '[]',  -- 관련 플레이어 ID 배열

    -- 클립 메타데이터
    metadata JSONB DEFAULT '{}',  -- {"pot_size": 1000000, "hand_rank": "Full House"}

    -- 내보내기 상태
    is_exported BOOLEAN DEFAULT FALSE,
    exported_at TIMESTAMPTZ,
    export_path TEXT,

    -- 상태
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'reviewed', 'exported', 'rejected'
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_clip_markers_hand ON clip_markers(hand_id);
CREATE INDEX IF NOT EXISTS idx_clip_markers_tournament ON clip_markers(tournament_id);
CREATE INDEX IF NOT EXISTS idx_clip_markers_type ON clip_markers(marker_type);
CREATE INDEX IF NOT EXISTS idx_clip_markers_grade ON clip_markers(grade) WHERE grade IN ('A', 'B');
CREATE INDEX IF NOT EXISTS idx_clip_markers_status ON clip_markers(status);
CREATE INDEX IF NOT EXISTS idx_clip_markers_exported ON clip_markers(is_exported) WHERE is_exported = FALSE;

-- Comment
COMMENT ON TABLE clip_markers IS '편집 마커 (클립 추출 및 하이라이트 생성용)';
COMMENT ON COLUMN clip_markers.start_timecode IS '시작 타임코드: HH:MM:SS:FF 형식';



-- ============================================================
-- FILE: 034_create_ai_results.sql
-- ============================================================

-- ============================================================
-- Migration: 034_create_ai_results.sql
-- Description: Supabase 통합 스키마 - ai_results 테이블 (신규)
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 4 - Broadcast System
-- Note: automation_feature_table 통합 - AI 분석 결과
-- ============================================================

-- ai_results - AI 분석 결과
CREATE TABLE IF NOT EXISTS ai_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID REFERENCES hands(id) ON DELETE CASCADE,
    player_id UUID REFERENCES players_master(id) ON DELETE SET NULL,

    -- AI 분석 타입
    analysis_type VARCHAR(50) NOT NULL,  -- 'card_detection', 'hand_evaluation', 'player_identification', 'grade_prediction'

    -- 분석 결과
    result JSONB NOT NULL DEFAULT '{}',
    confidence DECIMAL(5,4),  -- 0.0000 ~ 1.0000

    -- 카드 감지 결과 (card_detection 타입)
    detected_cards JSONB,  -- [{"rank": "A", "suit": "s", "confidence": 0.95}]

    -- 핸드 평가 결과 (hand_evaluation 타입)
    hand_rank VARCHAR(50),  -- "Full House", "Flush" 등
    rank_value INTEGER,  -- phevaluator 값

    -- 등급 예측 결과 (grade_prediction 타입)
    predicted_grade CHAR(1),  -- 'A', 'B', 'C', 'D'
    grade_confidence DECIMAL(5,4),

    -- 처리 정보
    model_version VARCHAR(50),  -- "gpt-4o-2024-08", "yolov8-cards-v2"
    processing_time_ms INTEGER,

    -- 상태
    status VARCHAR(20) DEFAULT 'completed',  -- 'processing', 'completed', 'failed'
    error_message TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_results_hand ON ai_results(hand_id);
CREATE INDEX IF NOT EXISTS idx_ai_results_player ON ai_results(player_id);
CREATE INDEX IF NOT EXISTS idx_ai_results_type ON ai_results(analysis_type);
CREATE INDEX IF NOT EXISTS idx_ai_results_status ON ai_results(status);
CREATE INDEX IF NOT EXISTS idx_ai_results_confidence ON ai_results(confidence DESC);
CREATE INDEX IF NOT EXISTS idx_ai_results_hand_type ON ai_results(hand_id, analysis_type);

-- Comment
COMMENT ON TABLE ai_results IS 'AI 분석 결과 (카드 감지, 핸드 평가, 등급 예측 등)';
COMMENT ON COLUMN ai_results.confidence IS '분석 신뢰도: 0.0 ~ 1.0';



-- ============================================================
-- FILE: 040_create_views.sql
-- ============================================================

-- ============================================================
-- Migration: 040_create_views.sql
-- Description: Supabase 통합 스키마 - Views
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 5 - Views & Functions
-- ============================================================

-- ============================================================
-- 1. Tournament Views
-- ============================================================

-- v_tournament_leaderboard - 토너먼트 리더보드
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

-- v_feature_table_players - 피처 테이블 플레이어
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

-- v_elimination_summary - 탈락 요약
CREATE OR REPLACE VIEW v_elimination_summary AS
SELECT
    e.id AS elimination_id,
    pm.name AS player_name,
    pm.display_name,
    pm.nationality,
    pm.photo_url,
    e.final_rank,
    e.payout_received,
    e.final_hand,
    e.losing_hand,
    pm_winner.name AS eliminated_by_name,
    e.eliminated_at,
    t.name AS tournament_name
FROM eliminations e
JOIN player_instances pi ON e.player_instance_id = pi.id
JOIN players_master pm ON pi.player_id = pm.id
JOIN tournaments t ON e.tournament_id = t.id
LEFT JOIN players_master pm_winner ON e.eliminated_by_id = pm_winner.id
ORDER BY e.eliminated_at DESC;

-- ============================================================
-- 2. Hand Views
-- ============================================================

-- v_hand_summary - 핸드 요약
CREATE OR REPLACE VIEW v_hand_summary AS
SELECT
    h.id AS hand_id,
    h.hand_number,
    h.game_variant,
    h.pot_size,
    h.grade,
    h.is_premium,
    h.started_at,
    h.completed_at,
    pm.name AS winner_name,
    h.winning_hand,
    gs.table_type,
    t.name AS tournament_name
FROM hands h
LEFT JOIN players_master pm ON h.winner_id = pm.id
LEFT JOIN gfx_sessions gs ON h.gfx_session_id = gs.id
LEFT JOIN tournaments t ON h.tournament_id = t.id
ORDER BY h.started_at DESC;

-- v_premium_hands - 프리미엄 핸드 (Grade A/B)
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

-- ============================================================
-- 3. Chip Flow Views
-- ============================================================

-- v_chip_flow_timeline - 칩 플로우 타임라인
CREATE OR REPLACE VIEW v_chip_flow_timeline AS
SELECT
    cf.id AS chip_flow_id,
    pm.name AS player_name,
    pm.display_name,
    cf.delta,
    cf.reason,
    cf.running_total,
    cf.hand_number,
    cf.level_number,
    cf.bb_count,
    cf.timestamp,
    t.name AS tournament_name
FROM chip_flow cf
JOIN player_instances pi ON cf.player_instance_id = pi.id
JOIN players_master pm ON pi.player_id = pm.id
JOIN tournaments t ON pi.tournament_id = t.id
ORDER BY cf.timestamp DESC;

-- ============================================================
-- 4. Graphics Queue Views
-- ============================================================

-- v_pending_graphics - 대기 중인 그래픽
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

-- Comment
COMMENT ON VIEW v_tournament_leaderboard IS '토너먼트 리더보드 (활성 플레이어만)';
COMMENT ON VIEW v_feature_table_players IS '피처 테이블 플레이어 (좌석순 정렬)';
COMMENT ON VIEW v_premium_hands IS '프리미엄 핸드 (Grade A/B)';



-- ============================================================
-- FILE: 041_create_functions.sql
-- ============================================================

-- ============================================================
-- Migration: 041_create_functions.sql
-- Description: Supabase 통합 스키마 - Functions
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 5 - Views & Functions
-- ============================================================

-- ============================================================
-- 1. Card Conversion Functions
-- ============================================================

-- convert_gfx_card: pokerGFX 카드 → DB 형식 변환
CREATE OR REPLACE FUNCTION convert_gfx_card(gfx_card TEXT)
RETURNS TEXT AS $$
DECLARE
    card_rank TEXT;
    card_suit TEXT;
BEGIN
    IF gfx_card IS NULL OR LENGTH(gfx_card) < 2 THEN
        RETURN NULL;
    END IF;

    -- 마지막 문자 = suit
    card_suit := LOWER(RIGHT(gfx_card, 1));

    -- 나머지 = rank
    card_rank := UPPER(LEFT(gfx_card, LENGTH(gfx_card) - 1));

    -- 10 → T 변환
    IF card_rank = '10' THEN
        card_rank := 'T';
    END IF;

    RETURN card_rank || card_suit;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- convert_gfx_hole_cards: 홀카드 배열 → 문자열 변환
CREATE OR REPLACE FUNCTION convert_gfx_hole_cards(hole_cards JSONB)
RETURNS TEXT AS $$
DECLARE
    card1 TEXT;
    card2 TEXT;
    cards_text TEXT;
BEGIN
    IF hole_cards IS NULL OR jsonb_array_length(hole_cards) < 2 THEN
        RETURN NULL;
    END IF;

    -- 첫 번째 요소 확인 (공백 구분 문자열 처리)
    cards_text := hole_cards->>0;

    IF cards_text LIKE '% %' THEN
        -- "10s 5h" 형식 → 분리
        card1 := convert_gfx_card(SPLIT_PART(cards_text, ' ', 1));
        card2 := convert_gfx_card(SPLIT_PART(cards_text, ' ', 2));
    ELSE
        -- ["7s", "7h"] 형식
        card1 := convert_gfx_card(hole_cards->>0);
        card2 := convert_gfx_card(hole_cards->>1);
    END IF;

    RETURN card1 || card2;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================
-- 2. Calculation Functions
-- ============================================================

-- calculate_bb_count: BB 수 계산
CREATE OR REPLACE FUNCTION calculate_bb_count(chips BIGINT, big_blind INTEGER)
RETURNS DECIMAL(10,2) AS $$
BEGIN
    IF big_blind IS NULL OR big_blind = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(chips::DECIMAL / big_blind, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- calculate_avg_stack_percentage: 평균 스택 대비 % 계산
CREATE OR REPLACE FUNCTION calculate_avg_stack_percentage(chips BIGINT, avg_stack INTEGER)
RETURNS DECIMAL(6,2) AS $$
BEGIN
    IF avg_stack IS NULL OR avg_stack = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND((chips::DECIMAL / avg_stack) * 100, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================
-- 3. Ranking Functions
-- ============================================================

-- update_player_ranks: 토너먼트 플레이어 순위 업데이트
CREATE OR REPLACE FUNCTION update_player_ranks(p_tournament_id UUID)
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER := 0;
BEGIN
    -- 칩 기준 순위 업데이트
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

-- ============================================================
-- 4. Lookup Functions
-- ============================================================

-- get_or_create_player_master: 플레이어 마스터 조회/생성
CREATE OR REPLACE FUNCTION get_or_create_player_master(
    p_name TEXT,
    p_nationality CHAR(2) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_player_id UUID;
BEGIN
    -- 기존 플레이어 조회
    SELECT id INTO v_player_id
    FROM players_master
    WHERE LOWER(name) = LOWER(p_name);

    -- 없으면 생성
    IF v_player_id IS NULL THEN
        INSERT INTO players_master (name, nationality)
        VALUES (p_name, p_nationality)
        RETURNING id INTO v_player_id;
    END IF;

    RETURN v_player_id;
END;
$$ LANGUAGE plpgsql;

-- Comment
COMMENT ON FUNCTION convert_gfx_card IS 'pokerGFX 카드 형식(as, 10d)을 DB 형식(As, Td)으로 변환';
COMMENT ON FUNCTION convert_gfx_hole_cards IS 'GFX 홀카드 JSONB를 문자열(AsKh)로 변환';
COMMENT ON FUNCTION update_player_ranks IS '토너먼트 플레이어 순위를 칩 기준으로 업데이트';



-- ============================================================
-- FILE: 042_create_triggers.sql
-- ============================================================

-- ============================================================
-- Migration: 042_create_triggers.sql
-- Description: Supabase 통합 스키마 - Triggers
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 5 - Views & Functions
-- ============================================================

-- ============================================================
-- 1. Chip Flow Trigger
-- ============================================================

-- 플레이어 칩 변동 시 자동으로 chip_flow 기록
CREATE OR REPLACE FUNCTION log_chip_flow()
RETURNS TRIGGER AS $$
DECLARE
    v_level_number INTEGER;
    v_big_blind INTEGER;
BEGIN
    -- 칩 변동이 없으면 무시
    IF OLD.chips = NEW.chips THEN
        RETURN NEW;
    END IF;

    -- 현재 블라인드 레벨 조회
    SELECT bl.level_number, bl.big_blind
    INTO v_level_number, v_big_blind
    FROM blind_levels bl
    WHERE bl.tournament_id = NEW.tournament_id
      AND bl.is_current = TRUE
    LIMIT 1;

    -- chip_flow 기록
    INSERT INTO chip_flow (
        player_instance_id,
        delta,
        reason,
        running_total,
        level_number,
        bb_count,
        source
    ) VALUES (
        NEW.id,
        NEW.chips - OLD.chips,
        CASE
            WHEN NEW.chips > OLD.chips THEN 'pot_win'
            WHEN NEW.chips < OLD.chips THEN 'pot_loss'
            ELSE 'unknown'
        END,
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

-- ============================================================
-- 2. Updated At Trigger
-- ============================================================

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 updated_at 트리거 적용
CREATE TRIGGER trg_venues_updated_at
    BEFORE UPDATE ON venues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_tournaments_updated_at
    BEFORE UPDATE ON tournaments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_players_master_updated_at
    BEFORE UPDATE ON players_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_player_instances_updated_at
    BEFORE UPDATE ON player_instances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_feature_tables_updated_at
    BEFORE UPDATE ON feature_tables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_gfx_sessions_updated_at
    BEFORE UPDATE ON gfx_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_commentators_updated_at
    BEFORE UPDATE ON commentators
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Comment
COMMENT ON FUNCTION log_chip_flow IS '플레이어 칩 변동 시 자동으로 chip_flow 테이블에 기록';
COMMENT ON FUNCTION update_updated_at IS 'updated_at 컬럼 자동 갱신';


