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
