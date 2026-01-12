-- ============================================================
-- Phase 4: Broadcast System Tables (5개)
-- Supabase SQL Editor에서 실행
-- ============================================================

-- 030: graphics_queue
CREATE TABLE IF NOT EXISTS graphics_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    hand_id UUID REFERENCES hands(id) ON DELETE SET NULL,
    graphic_type VARCHAR(50) NOT NULL,
    trigger_event VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    priority INTEGER DEFAULT 5,
    status VARCHAR(20) DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    scheduled_at TIMESTAMPTZ,
    rendered_at TIMESTAMPTZ,
    displayed_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ
);

-- 031: eliminations
CREATE TABLE IF NOT EXISTS eliminations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_instance_id UUID NOT NULL REFERENCES player_instances(id) ON DELETE CASCADE,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    elimination_hand_id UUID REFERENCES hands(id) ON DELETE SET NULL,
    hand_number INTEGER,
    final_rank INTEGER NOT NULL,
    payout_received DECIMAL(12,2) DEFAULT 0,
    eliminated_by_id UUID REFERENCES players_master(id) ON DELETE SET NULL,
    final_hand VARCHAR(50),
    losing_hand VARCHAR(50),
    final_chips BIGINT DEFAULT 0,
    eliminated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 032: soft_contents
CREATE TABLE IF NOT EXISTS soft_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    player_id UUID REFERENCES players_master(id) ON DELETE SET NULL,
    content_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    description TEXT,
    payload JSONB DEFAULT '{}',
    media_url TEXT,
    thumbnail_url TEXT,
    duration_seconds INTEGER,
    scheduled_at TIMESTAMPTZ,
    displayed_at TIMESTAMPTZ,
    priority INTEGER DEFAULT 5,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 033: clip_markers (신규)
CREATE TABLE IF NOT EXISTS clip_markers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID REFERENCES hands(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    marker_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    description TEXT,
    start_timecode VARCHAR(20),
    end_timecode VARCHAR(20),
    duration_seconds INTEGER,
    grade CHAR(1),
    player_ids JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    is_exported BOOLEAN DEFAULT FALSE,
    exported_at TIMESTAMPTZ,
    export_path TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 034: ai_results (신규)
CREATE TABLE IF NOT EXISTS ai_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID REFERENCES hands(id) ON DELETE CASCADE,
    player_id UUID REFERENCES players_master(id) ON DELETE SET NULL,
    analysis_type VARCHAR(50) NOT NULL,
    result JSONB NOT NULL DEFAULT '{}',
    confidence DECIMAL(5,4),
    detected_cards JSONB,
    hand_rank VARCHAR(50),
    rank_value INTEGER,
    predicted_grade CHAR(1),
    grade_confidence DECIMAL(5,4),
    model_version VARCHAR(50),
    processing_time_ms INTEGER,
    status VARCHAR(20) DEFAULT 'completed',
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_queue_tournament ON graphics_queue(tournament_id);
CREATE INDEX IF NOT EXISTS idx_queue_status ON graphics_queue(status);
CREATE INDEX IF NOT EXISTS idx_queue_pending ON graphics_queue(status, priority, created_at) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_eliminations_instance ON eliminations(player_instance_id);
CREATE INDEX IF NOT EXISTS idx_eliminations_tournament ON eliminations(tournament_id);
CREATE INDEX IF NOT EXISTS idx_eliminations_rank ON eliminations(final_rank);
CREATE INDEX IF NOT EXISTS idx_soft_contents_tournament ON soft_contents(tournament_id);
CREATE INDEX IF NOT EXISTS idx_soft_contents_type ON soft_contents(content_type);
CREATE INDEX IF NOT EXISTS idx_clip_markers_hand ON clip_markers(hand_id);
CREATE INDEX IF NOT EXISTS idx_clip_markers_grade ON clip_markers(grade) WHERE grade IN ('A', 'B');
CREATE INDEX IF NOT EXISTS idx_ai_results_hand ON ai_results(hand_id);
CREATE INDEX IF NOT EXISTS idx_ai_results_type ON ai_results(analysis_type);
