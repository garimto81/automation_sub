-- ============================================================
-- Migration: 20260108220000_wsop_caption_schema.sql
-- Description: WSOP 스키마에 Caption 시스템 테이블 생성
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: WSOP Caption System (21 tables, 7 views, 4 functions)
-- ============================================================

-- 스키마 설정
SET search_path TO wsop, public;

-- ============================================================
-- Phase 1: Core Reference Tables (7개)
-- ============================================================

-- 001: venues - 장소 정보
CREATE TABLE IF NOT EXISTS wsop.venues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    country CHAR(2),
    address TEXT,
    drone_shot_url TEXT,
    photo_urls JSONB DEFAULT '[]',
    timezone VARCHAR(50) DEFAULT 'UTC',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 002: events - 이벤트 정보
CREATE TABLE IF NOT EXISTS wsop.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    event_code VARCHAR(50) UNIQUE NOT NULL,
    venue_id UUID REFERENCES wsop.venues(id) ON DELETE SET NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'scheduled',
    logo_url TEXT,
    sponsor_logos JSONB DEFAULT '[]',
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 003: tournaments - 토너먼트 정보
CREATE TABLE IF NOT EXISTS wsop.tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES wsop.events(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    tournament_number INTEGER,
    buy_in DECIMAL(10,2) NOT NULL,
    starting_chips INTEGER NOT NULL,
    current_level INTEGER DEFAULT 1,
    current_day INTEGER DEFAULT 1,
    registered_players INTEGER DEFAULT 0,
    remaining_players INTEGER DEFAULT 0,
    unique_players INTEGER DEFAULT 0,
    prize_pool DECIMAL(15,2) DEFAULT 0,
    bubble_line INTEGER,
    is_itm BOOLEAN DEFAULT FALSE,
    is_registration_open BOOLEAN DEFAULT TRUE,
    registration_closes_at TIMESTAMPTZ,
    avg_stack INTEGER,
    status VARCHAR(20) DEFAULT 'scheduled',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 004: blind_levels - 블라인드 레벨
CREATE TABLE IF NOT EXISTS wsop.blind_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES wsop.tournaments(id) ON DELETE CASCADE,
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

-- 005: payouts - 상금 구조
CREATE TABLE IF NOT EXISTS wsop.payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES wsop.tournaments(id) ON DELETE CASCADE,
    place_start INTEGER NOT NULL,
    place_end INTEGER NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    percentage DECIMAL(5,2),
    is_current_bubble BOOLEAN DEFAULT FALSE,
    is_reached BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tournament_id, place_start, place_end)
);

-- 006: commentators - 해설자
CREATE TABLE IF NOT EXISTS wsop.commentators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    credentials TEXT,
    biography TEXT,
    social_links JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 007: schedules - 방송 일정
CREATE TABLE IF NOT EXISTS wsop.schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES wsop.events(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES wsop.tournaments(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    time_start TIME NOT NULL,
    time_end TIME,
    title VARCHAR(255) NOT NULL,
    channel VARCHAR(100),
    is_live BOOLEAN DEFAULT FALSE,
    is_current BOOLEAN DEFAULT FALSE,
    stream_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Phase 2: Player System (4개)
-- ============================================================

-- 010: players_master - 플레이어 마스터 (중복 방지)
CREATE TABLE IF NOT EXISTS wsop.players_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    nationality CHAR(2),
    wsop_player_id VARCHAR(50) UNIQUE,
    photo_url TEXT,
    biography TEXT,
    bracelets INTEGER DEFAULT 0,
    career_earnings DECIMAL(15,2) DEFAULT 0,
    social_links JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name, nationality)
);

-- 011: feature_tables - 피처 테이블 정보
CREATE TABLE IF NOT EXISTS wsop.feature_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES wsop.tournaments(id) ON DELETE CASCADE,
    table_number INTEGER NOT NULL,
    table_name VARCHAR(100),
    rfid_device_id VARCHAR(100),
    is_main BOOLEAN DEFAULT TRUE,
    is_live BOOLEAN DEFAULT FALSE,
    camera_positions JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tournament_id, table_number)
);

-- 012: player_instances - 플레이어 인스턴스 (토너먼트별)
CREATE TABLE IF NOT EXISTS wsop.player_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES wsop.players_master(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES wsop.tournaments(id) ON DELETE CASCADE,
    feature_table_id UUID REFERENCES wsop.feature_tables(id) ON DELETE SET NULL,
    seat_number INTEGER CHECK (seat_number >= 1 AND seat_number <= 10),
    chips BIGINT DEFAULT 0,
    current_rank INTEGER,
    is_feature_table BOOLEAN DEFAULT FALSE,
    is_eliminated BOOLEAN DEFAULT FALSE,
    elimination_rank INTEGER,
    payout_received DECIMAL(12,2),
    entry_number INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_id, tournament_id, entry_number)
);

-- 013: player_stats - 플레이어 실시간 통계
CREATE TABLE IF NOT EXISTS wsop.player_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES wsop.player_instances(id) ON DELETE CASCADE,
    vpip DECIMAL(5,2) DEFAULT 0,
    pfr DECIMAL(5,2) DEFAULT 0,
    aggression_factor DECIMAL(5,2) DEFAULT 0,
    wtsd DECIMAL(5,2) DEFAULT 0,
    hands_played INTEGER DEFAULT 0,
    hands_won INTEGER DEFAULT 0,
    total_bet BIGINT DEFAULT 0,
    total_won BIGINT DEFAULT 0,
    biggest_pot_won BIGINT DEFAULT 0,
    all_in_count INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_instance_id)
);

-- ============================================================
-- Phase 3: Hand System (6개)
-- ============================================================

-- 020: gfx_sessions - PokerGFX 세션
CREATE TABLE IF NOT EXISTS wsop.gfx_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gfx_id BIGINT UNIQUE NOT NULL,
    feature_table_id UUID REFERENCES wsop.feature_tables(id) ON DELETE SET NULL,
    event_title VARCHAR(255),
    table_type VARCHAR(50) DEFAULT 'FEATURE_TABLE',
    software_version VARCHAR(50),
    payouts JSONB DEFAULT '[]',
    total_hands INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    created_at_gfx TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 021: hands - 핸드 정보
CREATE TABLE IF NOT EXISTS wsop.hands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gfx_session_id UUID NOT NULL REFERENCES wsop.gfx_sessions(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES wsop.tournaments(id) ON DELETE CASCADE,
    hand_number INTEGER NOT NULL,
    game_variant VARCHAR(20) NOT NULL DEFAULT 'HOLDEM',
    game_class VARCHAR(20) DEFAULT 'FLOP',
    bet_structure VARCHAR(20) DEFAULT 'NOLIMIT',
    level_number INTEGER,
    button_seat INTEGER,
    small_blind_seat INTEGER,
    small_blind_amount DECIMAL(12,2),
    big_blind_seat INTEGER,
    big_blind_amount DECIMAL(12,2),
    ante_type VARCHAR(30),
    num_boards INTEGER DEFAULT 1,
    run_it_num_times INTEGER DEFAULT 1,
    duration INTERVAL,
    started_at TIMESTAMPTZ,
    winner_id UUID REFERENCES wsop.player_instances(id) ON DELETE SET NULL,
    final_pot DECIMAL(15,2),
    is_premium BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'in_progress',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(gfx_session_id, hand_number)
);

-- 022: hand_players - 핸드별 플레이어 상태
CREATE TABLE IF NOT EXISTS wsop.hand_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES wsop.hands(id) ON DELETE CASCADE,
    player_instance_id UUID NOT NULL REFERENCES wsop.player_instances(id) ON DELETE CASCADE,
    seat_number INTEGER NOT NULL CHECK (seat_number >= 1 AND seat_number <= 10),
    start_stack BIGINT NOT NULL,
    end_stack BIGINT,
    hole_cards VARCHAR(10),
    cumulative_winnings BIGINT DEFAULT 0,
    sitting_out BOOLEAN DEFAULT FALSE,
    vpip_percent DECIMAL(5,2),
    pfr_percent DECIMAL(5,2),
    aggression_percent DECIMAL(5,2),
    wtsd_percent DECIMAL(5,2),
    is_winner BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(hand_id, seat_number)
);

-- 023: hand_actions - 핸드 액션
CREATE TABLE IF NOT EXISTS wsop.hand_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES wsop.hands(id) ON DELETE CASCADE,
    player_instance_id UUID REFERENCES wsop.player_instances(id) ON DELETE SET NULL,
    seat_number INTEGER,
    street VARCHAR(20) NOT NULL,
    action_order INTEGER NOT NULL,
    action VARCHAR(20) NOT NULL,
    bet_amount DECIMAL(12,2) DEFAULT 0,
    pot_size_after DECIMAL(15,2),
    board_num INTEGER DEFAULT 1,
    num_cards_drawn INTEGER,
    action_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 024: hand_cards - 커뮤니티 카드
CREATE TABLE IF NOT EXISTS wsop.hand_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES wsop.hands(id) ON DELETE CASCADE,
    street VARCHAR(20) NOT NULL,
    board_num INTEGER DEFAULT 1,
    card_1 CHAR(2),
    card_2 CHAR(2),
    card_3 CHAR(2),
    gfx_cards JSONB,
    dealt_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(hand_id, street, board_num)
);

-- 025: chip_flow - 칩 변동 히스토리
CREATE TABLE IF NOT EXISTS wsop.chip_flow (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES wsop.player_instances(id) ON DELETE CASCADE,
    hand_id UUID REFERENCES wsop.hands(id) ON DELETE SET NULL,
    chips_before BIGINT NOT NULL,
    chips_after BIGINT NOT NULL,
    chip_change BIGINT NOT NULL,
    running_total BIGINT,
    bb_count DECIMAL(10,2),
    rank_before INTEGER,
    rank_after INTEGER,
    source VARCHAR(50),
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Phase 4: Broadcast System (5개)
-- ============================================================

-- 030: graphics_queue - 그래픽 렌더링 큐
CREATE TABLE IF NOT EXISTS wsop.graphics_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES wsop.tournaments(id) ON DELETE CASCADE,
    graphic_type VARCHAR(50) NOT NULL,
    trigger_event VARCHAR(50),
    priority INTEGER DEFAULT 5,
    payload JSONB NOT NULL,
    scheduled_at TIMESTAMPTZ,
    displayed_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 031: eliminations - 탈락 정보
CREATE TABLE IF NOT EXISTS wsop.eliminations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES wsop.player_instances(id) ON DELETE CASCADE,
    hand_id UUID REFERENCES wsop.hands(id) ON DELETE SET NULL,
    final_rank INTEGER NOT NULL,
    payout_received DECIMAL(12,2),
    eliminator_id UUID REFERENCES wsop.player_instances(id) ON DELETE SET NULL,
    player_hole_cards VARCHAR(10),
    eliminator_hole_cards VARCHAR(10),
    board_cards VARCHAR(20),
    was_broadcast BOOLEAN DEFAULT FALSE,
    eliminated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 032: soft_contents - 소프트 콘텐츠
CREATE TABLE IF NOT EXISTS wsop.soft_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES wsop.tournaments(id) ON DELETE CASCADE,
    player_instance_id UUID REFERENCES wsop.player_instances(id) ON DELETE SET NULL,
    content_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    description TEXT,
    media_url TEXT,
    priority INTEGER DEFAULT 5,
    scheduled_at TIMESTAMPTZ,
    displayed_at TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 033: clip_markers - 클립 마커
CREATE TABLE IF NOT EXISTS wsop.clip_markers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID REFERENCES wsop.hands(id) ON DELETE SET NULL,
    player_instance_id UUID REFERENCES wsop.player_instances(id) ON DELETE SET NULL,
    marker_type VARCHAR(50) NOT NULL,
    timestamp_start TIMESTAMPTZ NOT NULL,
    timestamp_end TIMESTAMPTZ,
    description TEXT,
    tags JSONB DEFAULT '[]',
    priority INTEGER DEFAULT 5,
    is_exported BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 034: ai_results - AI 분석 결과
CREATE TABLE IF NOT EXISTS wsop.ai_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID REFERENCES wsop.hands(id) ON DELETE SET NULL,
    player_instance_id UUID REFERENCES wsop.player_instances(id) ON DELETE SET NULL,
    analysis_type VARCHAR(50) NOT NULL,
    result JSONB NOT NULL,
    confidence DECIMAL(5,4),
    model_version VARCHAR(50),
    processed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Indexes
-- ============================================================

-- Phase 1
CREATE INDEX IF NOT EXISTS idx_wsop_venues_name ON wsop.venues(name);
CREATE INDEX IF NOT EXISTS idx_wsop_events_code ON wsop.events(event_code);
CREATE INDEX IF NOT EXISTS idx_wsop_events_status ON wsop.events(status);
CREATE INDEX IF NOT EXISTS idx_wsop_tournaments_event ON wsop.tournaments(event_id);
CREATE INDEX IF NOT EXISTS idx_wsop_tournaments_status ON wsop.tournaments(status);
CREATE INDEX IF NOT EXISTS idx_wsop_blinds_tournament ON wsop.blind_levels(tournament_id);
CREATE INDEX IF NOT EXISTS idx_wsop_payouts_tournament ON wsop.payouts(tournament_id);
CREATE INDEX IF NOT EXISTS idx_wsop_schedules_event ON wsop.schedules(event_id);
CREATE INDEX IF NOT EXISTS idx_wsop_schedules_date ON wsop.schedules(date);

-- Phase 2
CREATE INDEX IF NOT EXISTS idx_wsop_players_name ON wsop.players_master(name);
CREATE INDEX IF NOT EXISTS idx_wsop_players_nationality ON wsop.players_master(nationality);
CREATE INDEX IF NOT EXISTS idx_wsop_feature_tournament ON wsop.feature_tables(tournament_id);
CREATE INDEX IF NOT EXISTS idx_wsop_instances_player ON wsop.player_instances(player_id);
CREATE INDEX IF NOT EXISTS idx_wsop_instances_tournament ON wsop.player_instances(tournament_id);
CREATE INDEX IF NOT EXISTS idx_wsop_instances_chips ON wsop.player_instances(chips DESC);
CREATE INDEX IF NOT EXISTS idx_wsop_instances_rank ON wsop.player_instances(current_rank);
CREATE INDEX IF NOT EXISTS idx_wsop_stats_instance ON wsop.player_stats(player_instance_id);

-- Phase 3
CREATE INDEX IF NOT EXISTS idx_wsop_gfx_gfx_id ON wsop.gfx_sessions(gfx_id);
CREATE INDEX IF NOT EXISTS idx_wsop_gfx_status ON wsop.gfx_sessions(status);
CREATE INDEX IF NOT EXISTS idx_wsop_hands_session ON wsop.hands(gfx_session_id);
CREATE INDEX IF NOT EXISTS idx_wsop_hands_tournament ON wsop.hands(tournament_id);
CREATE INDEX IF NOT EXISTS idx_wsop_hands_number ON wsop.hands(hand_number);
CREATE INDEX IF NOT EXISTS idx_wsop_hands_premium ON wsop.hands(is_premium) WHERE is_premium = TRUE;
CREATE INDEX IF NOT EXISTS idx_wsop_hand_players_hand ON wsop.hand_players(hand_id);
CREATE INDEX IF NOT EXISTS idx_wsop_hand_players_instance ON wsop.hand_players(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_wsop_actions_hand ON wsop.hand_actions(hand_id);
CREATE INDEX IF NOT EXISTS idx_wsop_actions_street ON wsop.hand_actions(street);
CREATE INDEX IF NOT EXISTS idx_wsop_cards_hand ON wsop.hand_cards(hand_id);
CREATE INDEX IF NOT EXISTS idx_wsop_chip_flow_instance ON wsop.chip_flow(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_wsop_chip_flow_hand ON wsop.chip_flow(hand_id);
CREATE INDEX IF NOT EXISTS idx_wsop_chip_flow_time ON wsop.chip_flow(recorded_at DESC);

-- Phase 4
CREATE INDEX IF NOT EXISTS idx_wsop_queue_tournament ON wsop.graphics_queue(tournament_id);
CREATE INDEX IF NOT EXISTS idx_wsop_queue_type ON wsop.graphics_queue(graphic_type);
CREATE INDEX IF NOT EXISTS idx_wsop_queue_status ON wsop.graphics_queue(status);
CREATE INDEX IF NOT EXISTS idx_wsop_queue_priority ON wsop.graphics_queue(priority DESC, created_at);
CREATE INDEX IF NOT EXISTS idx_wsop_eliminations_instance ON wsop.eliminations(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_wsop_eliminations_rank ON wsop.eliminations(final_rank);
CREATE INDEX IF NOT EXISTS idx_wsop_soft_tournament ON wsop.soft_contents(tournament_id);
CREATE INDEX IF NOT EXISTS idx_wsop_soft_status ON wsop.soft_contents(status);
CREATE INDEX IF NOT EXISTS idx_wsop_clips_hand ON wsop.clip_markers(hand_id);
CREATE INDEX IF NOT EXISTS idx_wsop_clips_type ON wsop.clip_markers(marker_type);
CREATE INDEX IF NOT EXISTS idx_wsop_ai_hand ON wsop.ai_results(hand_id);
CREATE INDEX IF NOT EXISTS idx_wsop_ai_type ON wsop.ai_results(analysis_type);

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON SCHEMA wsop IS 'WSOP 방송 Caption 시스템 스키마';
COMMENT ON TABLE wsop.venues IS '이벤트 장소 정보';
COMMENT ON TABLE wsop.events IS 'WSOP 이벤트 시리즈';
COMMENT ON TABLE wsop.tournaments IS '개별 토너먼트 정보';
COMMENT ON TABLE wsop.players_master IS '플레이어 마스터 (중복 방지)';
COMMENT ON TABLE wsop.player_instances IS '토너먼트별 플레이어 인스턴스';
COMMENT ON TABLE wsop.gfx_sessions IS 'PokerGFX RFID 세션';
COMMENT ON TABLE wsop.hands IS '핸드 정보';
COMMENT ON TABLE wsop.hand_players IS '핸드별 플레이어 상태';
COMMENT ON TABLE wsop.hand_actions IS '핸드 액션 로그';
COMMENT ON TABLE wsop.chip_flow IS '칩 변동 히스토리';
COMMENT ON TABLE wsop.graphics_queue IS '그래픽 렌더링 큐';
COMMENT ON TABLE wsop.eliminations IS '탈락 정보';

-- search_path 복원
RESET search_path;
