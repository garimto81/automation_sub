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
