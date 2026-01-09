-- ============================================================================
-- Migration: 20260110000100_ae_schema_tables.sql
-- Description: After Effects template/composition metadata tables
-- Schema: ae
-- Tables: 7 (templates, compositions, composition_layers, layer_data_mappings,
--            data_types, render_jobs, render_outputs)
-- ============================================================================

-- ============================================================================
-- 1. ae.templates - AEP project files
-- ============================================================================
CREATE TABLE ae.templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    checksum VARCHAR(64),
    aep_version VARCHAR(20),
    composition_count INTEGER DEFAULT 0,
    text_layer_count INTEGER DEFAULT 0,
    description TEXT,
    tags JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE ae.templates IS 'After Effects project (.aep) files';
COMMENT ON COLUMN ae.templates.checksum IS 'SHA-256 hash for change detection';
COMMENT ON COLUMN ae.templates.tags IS 'Array of tags: ["WSOP", "Cyprus", "2025"]';

-- ============================================================================
-- 2. ae.compositions - Renderable compositions
-- ============================================================================
CREATE TABLE ae.compositions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES ae.templates(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    comp_type VARCHAR(50) NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    frame_rate DECIMAL(6,3),
    duration_frames INTEGER,
    duration_seconds DECIMAL(10,3) GENERATED ALWAYS AS (
        CASE WHEN frame_rate > 0
        THEN duration_frames / frame_rate
        ELSE NULL END
    ) STORED,
    layer_count INTEGER DEFAULT 0,
    text_layer_count INTEGER DEFAULT 0,
    image_layer_count INTEGER DEFAULT 0,
    video_layer_count INTEGER DEFAULT 0,
    render_settings JSONB DEFAULT '{}',
    is_renderable BOOLEAN DEFAULT TRUE,
    render_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(template_id, name)
);

COMMENT ON TABLE ae.compositions IS 'Renderable AE compositions';
COMMENT ON COLUMN ae.compositions.comp_type IS 'Type: leaderboard, player_profile, transition, event_info, etc.';
COMMENT ON COLUMN ae.compositions.render_settings IS 'JSON: {"format": "mp4", "codec": "h264", "quality": "high"}';

-- ============================================================================
-- 3. ae.composition_layers - Dynamic layers in compositions
-- ============================================================================
CREATE TABLE ae.composition_layers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    composition_id UUID NOT NULL REFERENCES ae.compositions(id) ON DELETE CASCADE,
    layer_name VARCHAR(255) NOT NULL,
    layer_type VARCHAR(30) NOT NULL,
    layer_index INTEGER NOT NULL,
    parent_layer_id UUID REFERENCES ae.composition_layers(id) ON DELETE SET NULL,
    is_dynamic BOOLEAN DEFAULT FALSE,
    dynamic_prefix VARCHAR(10),
    data_field VARCHAR(100),
    slot_index INTEGER,
    default_value TEXT,
    sample_value TEXT,
    in_point DECIMAL(10,3),
    out_point DECIMAL(10,3),
    transform_x DECIMAL(10,2),
    transform_y DECIMAL(10,2),
    transform_scale DECIMAL(6,2) DEFAULT 100,
    transform_rotation DECIMAL(6,2) DEFAULT 0,
    transform_opacity DECIMAL(5,2) DEFAULT 100,
    font_family VARCHAR(100),
    font_size DECIMAL(6,2),
    font_color VARCHAR(20),
    text_alignment VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(composition_id, layer_name)
);

COMMENT ON TABLE ae.composition_layers IS 'Layers within AE compositions (text, image, video, shape)';
COMMENT ON COLUMN ae.composition_layers.layer_type IS 'Type: text, image, video, shape, null, adjustment, camera, light';
COMMENT ON COLUMN ae.composition_layers.is_dynamic IS 'TRUE for data-bound layers (var_, img_, vid_ prefix)';
COMMENT ON COLUMN ae.composition_layers.dynamic_prefix IS 'Prefix: var_, img_, vid_';
COMMENT ON COLUMN ae.composition_layers.slot_index IS 'For slot-based patterns: Name 1, Name 2 -> slot_index 1, 2';

-- ============================================================================
-- 4. ae.data_types - Data type definitions
-- ============================================================================
CREATE TABLE ae.data_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL,
    display_name VARCHAR(255),
    description TEXT,
    schema_definition JSONB NOT NULL,
    example_data JSONB DEFAULT '{}',
    source_schema VARCHAR(50),
    source_table VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE ae.data_types IS 'Data type definitions for layer binding';
COMMENT ON COLUMN ae.data_types.category IS 'Category: master, event, tournament, player, broadcast';
COMMENT ON COLUMN ae.data_types.schema_definition IS 'JSON Schema for validation';
COMMENT ON COLUMN ae.data_types.source_schema IS 'Source schema: json, wsop_plus, manual';

-- ============================================================================
-- 5. ae.layer_data_mappings - Data binding configuration
-- ============================================================================
CREATE TABLE ae.layer_data_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    layer_id UUID UNIQUE NOT NULL REFERENCES ae.composition_layers(id) ON DELETE CASCADE,
    data_type_id UUID REFERENCES ae.data_types(id) ON DELETE SET NULL,
    source_schema VARCHAR(50) NOT NULL,
    source_table VARCHAR(100) NOT NULL,
    source_column VARCHAR(100) NOT NULL,
    source_path TEXT,
    transform_type VARCHAR(50),
    transform_config JSONB DEFAULT '{}',
    fallback_value TEXT,
    validation_regex VARCHAR(500),
    is_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE ae.layer_data_mappings IS 'Data binding from DB columns to AE layers';
COMMENT ON COLUMN ae.layer_data_mappings.source_schema IS 'Source schema: json, wsop_plus, manual';
COMMENT ON COLUMN ae.layer_data_mappings.source_path IS 'Nested path for JSONB: payouts[0].amount';
COMMENT ON COLUMN ae.layer_data_mappings.transform_type IS 'Transform: format_number, uppercase, lowercase, flag_path, currency';
COMMENT ON COLUMN ae.layer_data_mappings.transform_config IS 'Config: {"separator": ",", "prefix": "$", "suffix": "K"}';

-- ============================================================================
-- 6. ae.render_jobs - Nexrender job queue
-- ============================================================================
CREATE TABLE ae.render_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    composition_id UUID NOT NULL REFERENCES ae.compositions(id) ON DELETE SET NULL,
    data_type_id UUID REFERENCES ae.data_types(id) ON DELETE SET NULL,
    job_uid VARCHAR(100) UNIQUE,
    data_payload JSONB NOT NULL DEFAULT '{}',
    slot_data JSONB DEFAULT '[]',
    assets JSONB DEFAULT '[]',
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    status VARCHAR(30) DEFAULT 'pending',
    nexrender_worker VARCHAR(100),
    nexrender_job_id VARCHAR(100),
    progress INTEGER DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    queued_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    created_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE ae.render_jobs IS 'Nexrender render job queue';
COMMENT ON COLUMN ae.render_jobs.status IS 'Status: pending, queued, rendering, postprocessing, completed, failed, cancelled';
COMMENT ON COLUMN ae.render_jobs.data_payload IS 'Layer data values: {"player_name": "Daniel", "chips": 1000000}';
COMMENT ON COLUMN ae.render_jobs.slot_data IS 'Slot data array for leaderboards: [{"name": "...", "chips": ...}, ...]';
COMMENT ON COLUMN ae.render_jobs.assets IS 'Asset overrides: [{"src": "...", "layerName": "...", "type": "image"}]';

-- ============================================================================
-- 7. ae.render_outputs - Rendered output files
-- ============================================================================
CREATE TABLE ae.render_outputs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    render_job_id UUID NOT NULL REFERENCES ae.render_jobs(id) ON DELETE CASCADE,
    output_type VARCHAR(30) NOT NULL,
    file_path TEXT NOT NULL,
    file_name VARCHAR(255),
    file_size BIGINT,
    mime_type VARCHAR(100),
    width INTEGER,
    height INTEGER,
    duration_seconds DECIMAL(10,3),
    frame_count INTEGER,
    codec VARCHAR(50),
    bitrate INTEGER,
    has_alpha BOOLEAN DEFAULT FALSE,
    storage_bucket VARCHAR(100),
    storage_path TEXT,
    storage_url TEXT,
    cdn_url TEXT,
    checksum VARCHAR(64),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE ae.render_outputs IS 'Rendered output files (video, image sequence, GIF)';
COMMENT ON COLUMN ae.render_outputs.output_type IS 'Type: video, image_sequence, gif, png, jpg';
COMMENT ON COLUMN ae.render_outputs.storage_url IS 'Supabase Storage URL';
COMMENT ON COLUMN ae.render_outputs.cdn_url IS 'CDN URL for delivery';
