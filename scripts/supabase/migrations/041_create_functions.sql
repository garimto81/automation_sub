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
