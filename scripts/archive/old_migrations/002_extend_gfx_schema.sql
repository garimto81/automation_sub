-- ============================================================
-- Migration: 002_extend_gfx_schema.sql
-- Description: PRD-0004 pokerGFX 스키마 확장 (7개 신규 테이블)
-- Author: Claude Code
-- Date: 2026-01-06
-- PRD: PRD-0004 Caption Database Schema
-- Depends: 001_create_caption_tables.sql
-- ============================================================

BEGIN;

-- ============================================================
-- 1. Feature Tables Management
-- ============================================================

-- 1.1 feature_tables - 피처 테이블 관리
CREATE TABLE IF NOT EXISTS feature_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 테이블 정보
    table_number INTEGER NOT NULL,
    table_name VARCHAR(100),  -- "Feature Table 1", "Amazon Room"

    -- RFID/GFX 연동
    rfid_enabled BOOLEAN DEFAULT TRUE,
    rfid_device_id VARCHAR(100),

    -- 방송 상태
    is_live BOOLEAN DEFAULT FALSE,
    camera_position VARCHAR(50),  -- "Main", "Bird's Eye", "Rail"

    -- 활성 상태
    is_active BOOLEAN DEFAULT TRUE,
    activated_at TIMESTAMP,
    deactivated_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(tournament_id, table_number)
);

-- Add FK to players table
ALTER TABLE players
    ADD COLUMN IF NOT EXISTS feature_table_id UUID REFERENCES feature_tables(id);

-- ============================================================
-- 2. pokerGFX Session & Hand Tables
-- ============================================================

-- 2.1 gfx_sessions - pokerGFX 세션 데이터
CREATE TABLE IF NOT EXISTS gfx_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    feature_table_id UUID REFERENCES feature_tables(id) ON DELETE SET NULL,

    -- GFX 원본 데이터
    gfx_id BIGINT UNIQUE NOT NULL,  -- pokerGFX ID (638961999170907267)
    event_title VARCHAR(255),
    table_type VARCHAR(50) DEFAULT 'FEATURE_TABLE',  -- 'FEATURE_TABLE', 'OUTER_TABLE'
    software_version VARCHAR(50),  -- 'PokerGFX 3.2'

    -- 페이아웃 (JSONB)
    payouts JSONB DEFAULT '[]',  -- [0,0,0,0,0,0,0,0,0,0]

    -- 타임스탬프
    created_at_gfx TIMESTAMP NOT NULL,  -- GFX CreatedDateTimeUTC
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 상태
    status VARCHAR(20) DEFAULT 'active',  -- 'active', 'closed', 'archived'
    total_hands INTEGER DEFAULT 0
);

-- 2.2 hands - 핸드 메타정보 (GFX Hand 객체 매핑)
CREATE TABLE IF NOT EXISTS hands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gfx_session_id UUID REFERENCES gfx_sessions(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,

    -- 핸드 정보 (GFX HandNum)
    hand_number INTEGER NOT NULL,
    table_number INTEGER NOT NULL,

    -- 게임 정보 (GFX GameVariant, GameClass, BetStructure)
    game_variant VARCHAR(20) DEFAULT 'HOLDEM',  -- 'HOLDEM', 'OMAHA', 'STUD'
    game_class VARCHAR(20) DEFAULT 'FLOP',  -- 'FLOP', 'DRAW', 'STUD'
    bet_structure VARCHAR(20) DEFAULT 'NOLIMIT',  -- 'NOLIMIT', 'POTLIMIT', 'LIMIT'

    -- 블라인드 정보 (GFX FlopDrawBlinds)
    level_number INTEGER NOT NULL,
    button_seat INTEGER,  -- ButtonPlayerNum
    small_blind_seat INTEGER,  -- SmallBlindPlayerNum
    small_blind_amount DECIMAL(12,2),  -- SmallBlindAmt
    big_blind_seat INTEGER,  -- BigBlindPlayerNum
    big_blind_amount DECIMAL(12,2),  -- BigBlindAmt
    ante_type VARCHAR(30),  -- 'BB_ANTE_BB1ST', 'ANTE_ALL', etc.

    -- Run It 정보 (GFX NumBoards, RunItNumTimes)
    num_boards INTEGER DEFAULT 1,
    run_it_num_times INTEGER DEFAULT 1,

    -- 팟 정보
    pot_size DECIMAL(12,2) DEFAULT 0,
    rake DECIMAL(10,2) DEFAULT 0,

    -- 결과
    winner_id UUID REFERENCES players(id),
    winning_hand VARCHAR(50),  -- "Full House, Aces full of Kings"

    -- 시간 정보 (GFX Duration, StartDateTimeUTC)
    duration INTERVAL,  -- GFX Duration (PT2M56.2628165S → interval)
    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,

    -- 상태
    status VARCHAR(20) DEFAULT 'in_progress',  -- 'in_progress', 'completed', 'void'

    UNIQUE(tournament_id, hand_number, table_number)
);

-- Add FK to chip_history
ALTER TABLE chip_history
    ADD COLUMN IF NOT EXISTS hand_id UUID REFERENCES hands(id);

-- 2.3 hand_players - 핸드별 플레이어 상태 (GFX Player 객체 매핑)
CREATE TABLE IF NOT EXISTS hand_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,

    -- 시트 정보 (GFX PlayerNum)
    seat_number INTEGER NOT NULL,  -- 1-10

    -- 스택 정보 (GFX StartStackAmt, EndStackAmt, CumulativeWinningsAmt)
    start_stack DECIMAL(12,2) NOT NULL,
    end_stack DECIMAL(12,2) NOT NULL,
    cumulative_winnings DECIMAL(12,2) DEFAULT 0,

    -- 카드 정보 (GFX HoleCards, 변환된 형식: 'AsKh')
    hole_cards VARCHAR(10),

    -- 상태 (GFX SittingOut)
    sitting_out BOOLEAN DEFAULT FALSE,
    is_winner BOOLEAN DEFAULT FALSE,

    -- 실시간 통계 (GFX 제공)
    vpip_percent DECIMAL(5,2),  -- VPIPPercent
    pfr_percent DECIMAL(5,2),  -- PreFlopRaisePercent
    aggression_percent DECIMAL(5,2),  -- AggressionFrequencyPercent
    wtsd_percent DECIMAL(5,2),  -- WentToShowDownPercent

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(hand_id, seat_number)
);

-- ============================================================
-- 3. Hand Actions & Community Cards
-- ============================================================

-- 3.1 hand_actions - 핸드 액션 로그 (GFX Event 객체 매핑)
CREATE TABLE IF NOT EXISTS hand_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,  -- NULL for BOARD_CARD

    -- 포지션 정보 (GFX PlayerNum)
    seat_number INTEGER,  -- 1-10
    position_name VARCHAR(20),  -- 'BTN', 'SB', 'BB', 'UTG', 'MP', 'CO', etc.

    -- 액션 정보 (GFX Event)
    street VARCHAR(10) NOT NULL,  -- 'preflop', 'flop', 'turn', 'river'
    action_order INTEGER NOT NULL,  -- 해당 스트리트 내 순서
    action VARCHAR(20) NOT NULL,  -- 'fold', 'call', 'raise', 'check', 'bet', 'all-in', 'showdown'

    -- 베팅 정보 (GFX BetAmt, Pot)
    bet_amount DECIMAL(12,2),
    pot_size_after DECIMAL(12,2),

    -- 보드/드로우 정보 (GFX BoardNum, NumCardsDrawn)
    board_num INTEGER DEFAULT 0,  -- Run It Twice 지원
    num_cards_drawn INTEGER DEFAULT 0,  -- Draw games

    -- 타임스탬프 (GFX DateTimeUTC)
    timestamp TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3.2 community_cards - 커뮤니티 카드 (GFX BOARD CARD 이벤트)
CREATE TABLE IF NOT EXISTS community_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES hands(id) ON DELETE CASCADE,

    -- 스트리트 (GFX BOARD CARD event)
    street VARCHAR(10) NOT NULL,  -- 'flop', 'turn', 'river'

    -- 보드 번호 (GFX BoardNum - Run It Twice 지원)
    board_num INTEGER DEFAULT 0,

    -- 카드 정보 (변환된 형식: 'Ah', 'Ks', 'Td')
    card_1 CHAR(2),
    card_2 CHAR(2),  -- Flop only
    card_3 CHAR(2),  -- Flop only

    -- 원본 GFX 카드 (소문자: ["as", "kh", "7d"])
    gfx_cards JSONB,

    -- 소스
    source VARCHAR(20) DEFAULT 'gfx',  -- 'gfx', 'manual'

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(hand_id, street, board_num)
);

-- ============================================================
-- 4. Eliminations & Soft Contents
-- ============================================================

-- 4.1 eliminations - 탈락 상세 정보 (GFX EliminationRank)
CREATE TABLE IF NOT EXISTS eliminations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,

    -- 탈락 정보 (GFX EliminationRank)
    final_rank INTEGER NOT NULL,
    payout_received DECIMAL(12,2),

    -- 탈락 상황
    eliminated_by_id UUID REFERENCES players(id),
    elimination_hand_id UUID REFERENCES hands(id),

    -- 핸드 정보 (Heads-up)
    player_hole_cards VARCHAR(10),  -- 변환된 형식
    eliminator_hole_cards VARCHAR(10),

    -- 방송 표시 여부
    was_broadcast BOOLEAN DEFAULT FALSE,
    broadcast_at TIMESTAMP,

    eliminated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4.2 soft_contents - 소프트 콘텐츠 큐
CREATE TABLE IF NOT EXISTS soft_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,

    -- 콘텐츠 유형 (PRD-0001 4.6)
    content_type VARCHAR(50) NOT NULL,  -- 'player_intro', 'player_update', 'hand_highlight', 'interview', 'special_moment'

    -- 관련 플레이어
    player_id UUID REFERENCES players(id),

    -- 콘텐츠 정보
    title VARCHAR(255),
    description TEXT,
    media_url TEXT,

    -- 우선순위
    priority INTEGER DEFAULT 5,

    -- 상태
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'ready', 'played', 'skipped'

    -- 예약 시간
    scheduled_at TIMESTAMP,
    played_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. Indexes (GFX Tables)
-- ============================================================

-- feature_tables
CREATE INDEX IF NOT EXISTS idx_feature_tournament ON feature_tables(tournament_id);
CREATE INDEX IF NOT EXISTS idx_feature_active ON feature_tables(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_feature_live ON feature_tables(is_live) WHERE is_live = TRUE;

-- gfx_sessions
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_gfx_id ON gfx_sessions(gfx_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_tournament ON gfx_sessions(tournament_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_feature_table ON gfx_sessions(feature_table_id);
CREATE INDEX IF NOT EXISTS idx_gfx_sessions_status ON gfx_sessions(status);

-- hands
CREATE INDEX IF NOT EXISTS idx_hands_gfx_session ON hands(gfx_session_id);
CREATE INDEX IF NOT EXISTS idx_hands_tournament ON hands(tournament_id);
CREATE INDEX IF NOT EXISTS idx_hands_table ON hands(table_number);
CREATE INDEX IF NOT EXISTS idx_hands_number ON hands(hand_number DESC);
CREATE INDEX IF NOT EXISTS idx_hands_winner ON hands(winner_id);
CREATE INDEX IF NOT EXISTS idx_hands_game_variant ON hands(game_variant);
CREATE INDEX IF NOT EXISTS idx_hands_status ON hands(status);

-- hand_players
CREATE INDEX IF NOT EXISTS idx_hand_players_hand ON hand_players(hand_id);
CREATE INDEX IF NOT EXISTS idx_hand_players_player ON hand_players(player_id);
CREATE INDEX IF NOT EXISTS idx_hand_players_seat ON hand_players(seat_number);
CREATE INDEX IF NOT EXISTS idx_hand_players_winner ON hand_players(is_winner) WHERE is_winner = TRUE;

-- hand_actions
CREATE INDEX IF NOT EXISTS idx_actions_hand ON hand_actions(hand_id);
CREATE INDEX IF NOT EXISTS idx_actions_player ON hand_actions(player_id);
CREATE INDEX IF NOT EXISTS idx_actions_street ON hand_actions(street);
CREATE INDEX IF NOT EXISTS idx_actions_action ON hand_actions(action);
CREATE INDEX IF NOT EXISTS idx_actions_order ON hand_actions(hand_id, action_order);

-- community_cards
CREATE INDEX IF NOT EXISTS idx_community_hand ON community_cards(hand_id);
CREATE INDEX IF NOT EXISTS idx_community_street ON community_cards(street);
CREATE INDEX IF NOT EXISTS idx_community_board ON community_cards(board_num);

-- eliminations
CREATE INDEX IF NOT EXISTS idx_elim_tournament ON eliminations(tournament_id);
CREATE INDEX IF NOT EXISTS idx_elim_player ON eliminations(player_id);
CREATE INDEX IF NOT EXISTS idx_elim_rank ON eliminations(final_rank);
CREATE INDEX IF NOT EXISTS idx_elim_time ON eliminations(eliminated_at DESC);

-- soft_contents
CREATE INDEX IF NOT EXISTS idx_soft_tournament ON soft_contents(tournament_id);
CREATE INDEX IF NOT EXISTS idx_soft_player ON soft_contents(player_id);
CREATE INDEX IF NOT EXISTS idx_soft_status ON soft_contents(status);
CREATE INDEX IF NOT EXISTS idx_soft_scheduled ON soft_contents(scheduled_at);

COMMIT;

-- ============================================================
-- Rollback Script (if needed)
-- ============================================================
-- ALTER TABLE chip_history DROP COLUMN IF EXISTS hand_id;
-- ALTER TABLE players DROP COLUMN IF EXISTS feature_table_id;
-- DROP TABLE IF EXISTS soft_contents CASCADE;
-- DROP TABLE IF EXISTS eliminations CASCADE;
-- DROP TABLE IF EXISTS community_cards CASCADE;
-- DROP TABLE IF EXISTS hand_actions CASCADE;
-- DROP TABLE IF EXISTS hand_players CASCADE;
-- DROP TABLE IF EXISTS hands CASCADE;
-- DROP TABLE IF EXISTS gfx_sessions CASCADE;
-- DROP TABLE IF EXISTS feature_tables CASCADE;
