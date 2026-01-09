-- ============================================================================
-- Migration: 20260110000400_manual_schema_tables.sql
-- Description: User-entered master data
-- Schema: manual
-- Tables: 7 (players_master, player_profiles, commentators, venues, events,
--            feature_tables, seating_assignments)
-- ============================================================================

-- ============================================================================
-- 1. manual.players_master - Player master data (deduplication)
-- ============================================================================
CREATE TABLE manual.players_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Basic identification
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    nationality CHAR(2),
    nationality_display VARCHAR(100),

    -- Photos
    photo_url TEXT,
    photo_thumbnail_url TEXT,
    photo_source VARCHAR(50),
    photo_updated_at TIMESTAMPTZ,

    -- External IDs
    hendon_mob_id VARCHAR(50) UNIQUE,
    gpi_id VARCHAR(50) UNIQUE,
    wsop_player_id VARCHAR(50) UNIQUE,
    cardplayer_id VARCHAR(50),
    pokernews_id VARCHAR(50),

    -- WSOP achievements
    wsop_bracelets INTEGER DEFAULT 0,
    wsop_rings INTEGER DEFAULT 0,
    wsop_final_tables INTEGER DEFAULT 0,
    wsop_cashes INTEGER DEFAULT 0,
    wsop_earnings DECIMAL(15,2) DEFAULT 0,

    -- Overall career
    total_earnings DECIMAL(15,2) DEFAULT 0,
    total_final_tables INTEGER DEFAULT 0,
    total_cashes INTEGER DEFAULT 0,
    career_titles INTEGER DEFAULT 0,

    -- Profile info
    biography TEXT,
    biography_short VARCHAR(500),
    notable_wins JSONB DEFAULT '[]',
    hometown VARCHAR(255),
    residence VARCHAR(255),
    profession VARCHAR(255),

    -- Social media
    social_links JSONB DEFAULT '{}',
    twitter_handle VARCHAR(100),
    instagram_handle VARCHAR(100),

    -- Key player flag
    is_key_player BOOLEAN DEFAULT FALSE,
    key_player_reason TEXT,
    key_player_priority INTEGER DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    verified_by VARCHAR(100),

    -- Merge tracking (for deduplication)
    merged_into_id UUID REFERENCES manual.players_master(id),
    alternate_names JSONB DEFAULT '[]',

    -- Data quality
    data_completeness INTEGER DEFAULT 0,
    last_data_update TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT players_name_nationality_uk UNIQUE (name, nationality)
);

COMMENT ON TABLE manual.players_master IS 'Master player registry (deduplicated across tournaments)';
COMMENT ON COLUMN manual.players_master.nationality IS 'ISO 3166-1 alpha-2 country code';
COMMENT ON COLUMN manual.players_master.notable_wins IS 'Array: [{"event": "WSOP ME", "year": 2023, "prize": 12100000}]';
COMMENT ON COLUMN manual.players_master.social_links IS 'Object: {"twitter": "@...", "instagram": "...", "youtube": "..."}';
COMMENT ON COLUMN manual.players_master.data_completeness IS 'Score 0-100 based on filled fields';

-- ============================================================================
-- 2. manual.player_profiles - Extended player profile
-- ============================================================================
CREATE TABLE manual.player_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID UNIQUE NOT NULL REFERENCES manual.players_master(id) ON DELETE CASCADE,

    -- Full name details
    long_name VARCHAR(500),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    nickname VARCHAR(100),
    alternative_names JSONB DEFAULT '[]',

    -- Personal info
    birth_date DATE,
    age INTEGER,  -- Calculated via application or view
    birth_place VARCHAR(255),

    -- Physical (optional, for graphics)
    height_cm INTEGER,
    poker_start_year INTEGER,
    years_playing INTEGER,  -- Calculated via application or view

    -- Playing style
    playing_style VARCHAR(50),
    preferred_game VARCHAR(50),
    signature_moves JSONB DEFAULT '[]',
    famous_quotes JSONB DEFAULT '[]',

    -- Career details
    career_highlights TEXT,
    biggest_win_amount DECIMAL(15,2),
    biggest_win_event VARCHAR(255),
    biggest_win_year INTEGER,

    -- Media
    interview_clips JSONB DEFAULT '[]',
    photo_gallery JSONB DEFAULT '[]',
    video_highlights JSONB DEFAULT '[]',

    -- Sponsorship
    sponsor VARCHAR(255),
    sponsor_logo_url TEXT,
    is_sponsored BOOLEAN DEFAULT FALSE,

    -- Notes
    internal_notes TEXT,
    broadcast_notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE manual.player_profiles IS 'Extended player profile information';
COMMENT ON COLUMN manual.player_profiles.playing_style IS 'Style: aggressive, tight, loose, LAG, TAG, etc.';
COMMENT ON COLUMN manual.player_profiles.preferred_game IS 'Game: NLHE, PLO, Mixed, Stud, etc.';
COMMENT ON COLUMN manual.player_profiles.interview_clips IS 'Array: [{"url": "...", "title": "...", "date": "..."}]';

-- ============================================================================
-- 3. manual.commentators - Broadcast commentary team
-- ============================================================================
CREATE TABLE manual.commentators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Basic info
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    nickname VARCHAR(100),

    -- Photos
    photo_url TEXT,
    photo_thumbnail_url TEXT,

    -- Credentials
    credentials TEXT,
    title VARCHAR(100),
    company VARCHAR(255),

    -- Biography
    biography TEXT,
    biography_short VARCHAR(500),

    -- Social media
    social_handle VARCHAR(100),
    social_links JSONB DEFAULT '{}',
    twitter_handle VARCHAR(100),
    instagram_handle VARCHAR(100),

    -- Expertise
    specialties JSONB DEFAULT '[]',
    languages JSONB DEFAULT '["en"]',
    years_experience INTEGER,

    -- Poker credentials (if applicable)
    is_player BOOLEAN DEFAULT FALSE,
    player_id UUID REFERENCES manual.players_master(id),
    wsop_bracelets INTEGER DEFAULT 0,
    notable_wins JSONB DEFAULT '[]',

    -- Scheduling
    availability_notes TEXT,
    preferred_events JSONB DEFAULT '[]',

    -- Contact (internal)
    email VARCHAR(255),
    phone VARCHAR(50),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_primary BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE manual.commentators IS 'Broadcast commentary team';
COMMENT ON COLUMN manual.commentators.credentials IS 'Display credentials: "2x WSOP Champion", "Poker Hall of Fame"';
COMMENT ON COLUMN manual.commentators.specialties IS 'Array: ["tournament", "cash", "mixed games", "analysis"]';
COMMENT ON COLUMN manual.commentators.is_primary IS 'TRUE for lead commentator role';

-- ============================================================================
-- 4. manual.venues - Event venues
-- ============================================================================
CREATE TABLE manual.venues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Basic info
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(100),
    official_name VARCHAR(500),

    -- Location
    city VARCHAR(100),
    state VARCHAR(100),
    country CHAR(2),
    country_display VARCHAR(100),
    address TEXT,
    postal_code VARCHAR(20),

    -- Coordinates
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),

    -- Timezone
    timezone VARCHAR(50) DEFAULT 'UTC',
    utc_offset VARCHAR(10),

    -- Media
    drone_shot_url TEXT,
    exterior_photo_url TEXT,
    interior_photo_url TEXT,
    poker_room_photo_url TEXT,
    photo_gallery JSONB DEFAULT '[]',
    video_url TEXT,

    -- Facility info
    capacity INTEGER,
    table_count INTEGER,
    poker_room_name VARCHAR(255),
    poker_room_size_sqft INTEGER,

    -- Amenities
    amenities JSONB DEFAULT '[]',
    nearby_hotels JSONB DEFAULT '[]',
    restaurants JSONB DEFAULT '[]',

    -- Contact
    website_url TEXT,
    phone VARCHAR(50),
    email VARCHAR(255),

    -- Description
    description TEXT,
    history TEXT,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE manual.venues IS 'Event venue information';
COMMENT ON COLUMN manual.venues.country IS 'ISO 3166-1 alpha-2 country code';
COMMENT ON COLUMN manual.venues.amenities IS 'Array: ["parking", "wifi", "restaurant", "hotel"]';
COMMENT ON COLUMN manual.venues.nearby_hotels IS 'Array: [{"name": "...", "distance": "0.5mi"}]';

-- ============================================================================
-- 5. manual.events - Event/Series information
-- ============================================================================
CREATE TABLE manual.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Basic info
    name VARCHAR(255) NOT NULL,
    event_code VARCHAR(50) UNIQUE NOT NULL,
    series_name VARCHAR(255),
    series_code VARCHAR(50),

    -- Venue
    venue_id UUID REFERENCES manual.venues(id) ON DELETE SET NULL,
    venue_name VARCHAR(255),

    -- Dates
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    duration_days INTEGER GENERATED ALWAYS AS (
        end_date - start_date + 1
    ) STORED,

    -- Status
    status VARCHAR(20) DEFAULT 'scheduled',

    -- Branding
    logo_url TEXT,
    logo_dark_url TEXT,
    banner_url TEXT,
    primary_color VARCHAR(20),
    secondary_color VARCHAR(20),
    sponsor_logos JSONB DEFAULT '[]',

    -- Description
    description TEXT,
    tagline VARCHAR(255),

    -- Schedule
    tournament_count INTEGER DEFAULT 0,
    total_prize_pool DECIMAL(15,2),
    featured_events JSONB DEFAULT '[]',

    -- Media
    website_url TEXT,
    social_links JSONB DEFAULT '{}',
    hashtag VARCHAR(100),

    -- Broadcast
    broadcast_partner VARCHAR(100),
    stream_url TEXT,

    -- Notes
    internal_notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE manual.events IS 'Event/Series information (e.g., WSOP Super Circuit Cyprus 2026)';
COMMENT ON COLUMN manual.events.event_code IS 'Unique code: WSOP_2026_LV, WSOP_SC_CYPRUS_2026';
COMMENT ON COLUMN manual.events.status IS 'Status: scheduled, upcoming, active, completed, cancelled';
COMMENT ON COLUMN manual.events.sponsor_logos IS 'Array: [{"name": "GGPoker", "url": "...", "position": "main"}]';

-- ============================================================================
-- 6. manual.feature_tables - Feature table management
-- ============================================================================
CREATE TABLE manual.feature_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Table info
    table_number INTEGER NOT NULL,
    table_name VARCHAR(100),
    table_location VARCHAR(255),

    -- Device IDs
    rfid_device_id VARCHAR(100),
    gfx_table_id VARCHAR(100),
    dealer_screen_id VARCHAR(100),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_streaming BOOLEAN DEFAULT FALSE,
    is_main_feature BOOLEAN DEFAULT FALSE,

    -- Camera setup
    camera_positions JSONB DEFAULT '{}',
    camera_config JSONB DEFAULT '{}',
    audio_config JSONB DEFAULT '{}',

    -- Lighting
    lighting_preset VARCHAR(50),

    -- Timing
    activated_at TIMESTAMPTZ,
    deactivated_at TIMESTAMPTZ,
    stream_started_at TIMESTAMPTZ,
    stream_ended_at TIMESTAMPTZ,

    -- Player count
    max_seats INTEGER DEFAULT 9,
    current_player_count INTEGER DEFAULT 0,

    -- Cross-references (soft FK)
    tournament_id UUID,
    event_id UUID,
    venue_id UUID,

    -- Notes
    setup_notes TEXT,
    technical_notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tournament_id, table_number)
);

COMMENT ON TABLE manual.feature_tables IS 'Feature table configuration and status';
COMMENT ON COLUMN manual.feature_tables.camera_positions IS 'Object: {"main": {...}, "overhead": {...}, "player_cams": [...]}';
COMMENT ON COLUMN manual.feature_tables.is_main_feature IS 'TRUE if this is THE primary feature table';
COMMENT ON COLUMN manual.feature_tables.tournament_id IS 'Soft FK to wsop_plus.tournaments';

-- ============================================================================
-- 7. manual.seating_assignments - Player seating
-- ============================================================================
CREATE TABLE manual.seating_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    player_id UUID NOT NULL REFERENCES manual.players_master(id) ON DELETE CASCADE,
    feature_table_id UUID NOT NULL REFERENCES manual.feature_tables(id) ON DELETE CASCADE,

    -- Seat info
    seat_number INTEGER NOT NULL CHECK (seat_number BETWEEN 1 AND 10),
    seat_position VARCHAR(20),

    -- Timing
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    removed_at TIMESTAMPTZ,
    duration_minutes INTEGER GENERATED ALWAYS AS (
        CASE WHEN removed_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (removed_at - assigned_at))::INTEGER / 60
        ELSE NULL END
    ) STORED,

    -- Status
    is_current BOOLEAN DEFAULT TRUE,
    removal_reason VARCHAR(100),

    -- Player state at assignment
    chips_at_assignment BIGINT,
    rank_at_assignment INTEGER,

    -- Notes
    notes TEXT,

    -- Assignment tracking
    assigned_by VARCHAR(100),
    assignment_source VARCHAR(50) DEFAULT 'manual',

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Only one current player per seat
    CONSTRAINT unique_current_seat UNIQUE (feature_table_id, seat_number, is_current)
);

COMMENT ON TABLE manual.seating_assignments IS 'Player seating at feature tables';
COMMENT ON COLUMN manual.seating_assignments.seat_position IS 'Position: button, sb, bb, utg, etc.';
COMMENT ON COLUMN manual.seating_assignments.removal_reason IS 'Reason: eliminated, table_break, redraw, moved';
COMMENT ON COLUMN manual.seating_assignments.assignment_source IS 'Source: manual, csv_import, api';

-- Create partial unique index for current assignments
CREATE UNIQUE INDEX idx_seating_current_unique
ON manual.seating_assignments (feature_table_id, seat_number)
WHERE is_current = TRUE;
