# Manual Input Migration Guide

**Version**: 1.0.0 | **Target Schema**: `manual`

---

## 1. Overview

### 1.1 Purpose

운영팀이 직접 입력하는 마스터 데이터를 `manual` 스키마로 관리하는 가이드. 자동화할 수 없는 프로필, 코멘테이터, 좌석 배정 등의 데이터를 다룹니다.

### 1.2 Data Flow

```
Admin Web UI / Spreadsheet
        |
        v
REST API / GraphQL / Bulk Import
        |
        +-- manual.players_master
        |     +-- manual.player_profiles
        |
        +-- manual.commentators
        +-- manual.venues
        +-- manual.events
        +-- manual.feature_tables
              +-- manual.seating_assignments
```

### 1.3 Target Tables (7)

| Table | Description | Input Method |
|-------|-------------|--------------|
| `manual.players_master` | 플레이어 마스터 레지스트리 | UI / Bulk |
| `manual.player_profiles` | 상세 프로필 정보 | UI |
| `manual.commentators` | 코멘테이터 정보 | UI |
| `manual.venues` | 장소/베뉴 정보 | UI / Bulk |
| `manual.events` | 이벤트/시리즈 정보 | UI |
| `manual.feature_tables` | Feature Table 설정 | UI |
| `manual.seating_assignments` | 좌석 배정 | UI (실시간) |

### 1.4 담당자

| Role | Responsibility |
|------|----------------|
| **PA (Production Assistant)** | 좌석 배정, 플레이어 정보 확인 |
| **PD (Producer/Director)** | 코멘테이터, 이벤트 설정 |
| **Data Manager** | 플레이어 마스터, 벌크 임포트 |

---

## 2. Input Methods

### 2.1 Admin Web UI

주요 입력 방식. React 기반 관리자 페이지에서 폼 입력.

```
┌─────────────────────────────────────────────────────────────────┐
│                      Admin Dashboard                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Players   │  │ Commentators│  │   Venues    │             │
│  │   Master    │  │             │  │             │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Events    │  │  Feature    │  │   Seating   │             │
│  │             │  │   Tables    │  │ Assignments │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Quick Actions                            │ │
│  │  [+ Add Player]  [Import CSV]  [Assign Seat]  [Export]     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Bulk Import (CSV/Excel)

대량 데이터 초기 설정 시 사용.

**Supported Tables**:
- `players_master` - 플레이어 마스터 벌크 임포트
- `venues` - 베뉴 정보 벌크 임포트
- `blind_levels` (wsop_plus로 연동)

### 2.3 REST API

외부 시스템 연동 또는 자동화 스크립트용.

```
POST   /api/manual/players          - 플레이어 생성
GET    /api/manual/players/:id      - 플레이어 조회
PUT    /api/manual/players/:id      - 플레이어 수정
DELETE /api/manual/players/:id      - 플레이어 삭제

POST   /api/manual/seating/assign   - 좌석 배정
DELETE /api/manual/seating/:id      - 좌석 해제
```

---

## 3. Table Specifications

### 3.1 players_master

플레이어 통합 레지스트리. 모든 토너먼트에서 공유되는 마스터 데이터.

#### 3.1.1 Required Fields

| Field | Type | Validation | Example |
|-------|------|------------|---------|
| `name` | VARCHAR(255) | Non-empty | "Daniel Negreanu" |
| `nationality` | CHAR(2) | ISO 3166-1 alpha-2 | "CA" |

#### 3.1.2 Optional Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `display_name` | VARCHAR(255) | 표시용 이름 | "Kid Poker" |
| `photo_url` | TEXT | 프로필 사진 URL | https://... |
| `hendon_mob_id` | VARCHAR(50) | HendonMob ID | "phil-ivey" |
| `wsop_bracelets` | INTEGER | WSOP 브레이슬릿 수 | 6 |
| `total_earnings` | DECIMAL(15,2) | 총 수익 | 45000000.00 |
| `is_key_player` | BOOLEAN | 주요 플레이어 여부 | true |
| `social_links` | JSONB | 소셜 미디어 링크 | {"twitter": "@..."} |

#### 3.1.3 UI Form Design

```
┌─────────────────────────────────────────────────────────────────┐
│                    Add/Edit Player                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Basic Information                                               │
│  ─────────────────                                               │
│  Name*:        [Daniel Negreanu                              ]   │
│  Display Name: [Kid Poker                                    ]   │
│  Nationality*: [CA - Canada                              ▼]     │
│                                                                  │
│  Photo                                                           │
│  ─────                                                           │
│  ┌─────────────┐                                                │
│  │   [Photo]   │  [Upload]  [URL]  [HendonMob]                  │
│  └─────────────┘                                                │
│                                                                  │
│  Career Stats                                                    │
│  ────────────                                                    │
│  WSOP Bracelets: [6   ]   WSOP Rings:  [2   ]                   │
│  Total Earnings: [$45,000,000        ]                          │
│  WSOP Earnings:  [$25,000,000        ]                          │
│                                                                  │
│  External IDs                                                    │
│  ────────────                                                    │
│  HendonMob:    [daniel-negreanu                              ]   │
│  GPI ID:       [12345                                        ]   │
│  WSOP ID:      [WSOP123456                                   ]   │
│                                                                  │
│  Social Media                                                    │
│  ────────────                                                    │
│  Twitter:   [@RealKidPoker                                   ]   │
│  Instagram: [realkidpoker                                    ]   │
│                                                                  │
│  Key Player                                                      │
│  ──────────                                                      │
│  [✓] Mark as Key Player                                         │
│  Reason: [6-time WSOP Champion, High profile               ]    │
│  Priority: [1  ] (1=highest)                                    │
│                                                                  │
│                          [Cancel]  [Save]                       │
└─────────────────────────────────────────────────────────────────┘
```

#### 3.1.4 Input Validation

```python
from pydantic import BaseModel, validator, Field
from typing import Optional
import re

class PlayerMasterInput(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    nationality: str = Field(..., min_length=2, max_length=2)
    display_name: Optional[str] = Field(None, max_length=255)
    photo_url: Optional[str] = None
    hendon_mob_id: Optional[str] = Field(None, max_length=50)
    wsop_bracelets: Optional[int] = Field(0, ge=0)
    total_earnings: Optional[float] = Field(0, ge=0)
    is_key_player: Optional[bool] = False

    @validator('nationality')
    def validate_nationality(cls, v):
        # ISO 3166-1 alpha-2 validation
        valid_codes = ['US', 'CA', 'GB', 'DE', 'FR', 'IT', 'ES', 'BR', ...]
        if v.upper() not in valid_codes:
            raise ValueError(f'Invalid country code: {v}')
        return v.upper()

    @validator('photo_url')
    def validate_photo_url(cls, v):
        if v and not v.startswith(('http://', 'https://')):
            raise ValueError('Photo URL must be a valid HTTP(S) URL')
        return v

    @validator('hendon_mob_id')
    def normalize_hendon_mob_id(cls, v):
        if v:
            # Convert to slug format
            return re.sub(r'[^a-z0-9-]', '-', v.lower())
        return v
```

### 3.2 player_profiles

players_master의 확장 프로필 (1:1 관계).

#### 3.2.1 Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `player_id` | UUID (FK) | 플레이어 마스터 ID | - |
| `long_name` | VARCHAR(500) | 전체 이름 | "Daniel Negreanu" |
| `birth_date` | DATE | 생년월일 | 1974-07-26 |
| `playing_style` | VARCHAR(50) | 플레이 스타일 | "LAG" |
| `preferred_game` | VARCHAR(50) | 선호 게임 | "NLHE" |
| `biography` | TEXT | 약력 | "Canadian..." |
| `career_highlights` | TEXT | 주요 경력 | "6x WSOP..." |
| `sponsor` | VARCHAR(255) | 스폰서 | "GGPoker" |

#### 3.2.2 Playing Style Options

```typescript
const PLAYING_STYLES = [
  { value: 'TAG', label: 'Tight Aggressive' },
  { value: 'LAG', label: 'Loose Aggressive' },
  { value: 'TP', label: 'Tight Passive' },
  { value: 'LP', label: 'Loose Passive' },
  { value: 'GTO', label: 'GTO-based' },
  { value: 'exploitative', label: 'Exploitative' },
  { value: 'mixed', label: 'Mixed/Adaptive' },
];

const PREFERRED_GAMES = [
  { value: 'NLHE', label: "No Limit Hold'em" },
  { value: 'PLO', label: 'Pot Limit Omaha' },
  { value: 'mixed', label: 'Mixed Games' },
  { value: 'stud', label: 'Stud Games' },
  { value: 'lowball', label: 'Lowball/Draw' },
];
```

### 3.3 commentators

코멘테이터/해설자 정보.

#### 3.3.1 Fields

| Field | Type | Required | Example |
|-------|------|----------|---------|
| `name` | VARCHAR(255) | Yes | "Lon McEachern" |
| `credentials` | TEXT | No | "WSOP Broadcaster since 2003" |
| `photo_url` | TEXT | No | https://... |
| `social_handle` | VARCHAR(100) | No | "@lonmceachern" |
| `is_player` | BOOLEAN | No | false |
| `player_id` | UUID | No | (if is_player=true) |
| `is_primary` | BOOLEAN | No | true |

#### 3.3.2 UI Form Design

```
┌─────────────────────────────────────────────────────────────────┐
│                    Add/Edit Commentator                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Basic Information                                               │
│  ─────────────────                                               │
│  Name*:         [Lon McEachern                               ]   │
│  Display Name:  [Lon                                         ]   │
│  Title:         [Lead Commentator                            ]   │
│                                                                  │
│  Credentials                                                     │
│  ───────────                                                     │
│  [WSOP Broadcaster since 2003. Known for his calm             ]  │
│  [delivery and encyclopedic knowledge of poker history.       ]  │
│                                                                  │
│  Photo                                                           │
│  ─────                                                           │
│  ┌─────────────┐                                                │
│  │   [Photo]   │  [Upload]  [URL]                               │
│  └─────────────┘                                                │
│                                                                  │
│  Social Media                                                    │
│  ────────────                                                    │
│  Twitter:   [@lonmceachern                                   ]   │
│  Instagram: [lonmceachern                                    ]   │
│                                                                  │
│  Poker Background                                                │
│  ────────────────                                                │
│  [✓] Also a poker player                                        │
│  Link to Player: [Search Players...                        ▼]   │
│                                                                  │
│  Role                                                            │
│  ────                                                            │
│  [✓] Primary Commentator                                        │
│                                                                  │
│                          [Cancel]  [Save]                       │
└─────────────────────────────────────────────────────────────────┘
```

### 3.4 venues

이벤트 장소 정보.

#### 3.4.1 Fields

| Field | Type | Required | Example |
|-------|------|----------|---------|
| `name` | VARCHAR(255) | Yes | "Paris Las Vegas" |
| `city` | VARCHAR(100) | Yes | "Las Vegas" |
| `country` | CHAR(2) | Yes | "US" |
| `timezone` | VARCHAR(50) | Yes | "America/Los_Angeles" |
| `drone_shot_url` | TEXT | No | https://... |
| `capacity` | INTEGER | No | 10000 |
| `table_count` | INTEGER | No | 500 |

### 3.5 events

이벤트/시리즈 정보.

#### 3.5.1 Fields

| Field | Type | Required | Example |
|-------|------|----------|---------|
| `event_code` | VARCHAR(50) | Yes | "WSOP_2026_LV" |
| `name` | VARCHAR(255) | Yes | "2026 World Series of Poker" |
| `series_name` | VARCHAR(255) | No | "WSOP" |
| `venue_id` | UUID (FK) | No | - |
| `start_date` | DATE | Yes | 2026-05-28 |
| `end_date` | DATE | Yes | 2026-07-17 |
| `sponsor_logos` | JSONB | No | [{"name": "GGPoker", ...}] |

### 3.6 feature_tables

Feature Table 설정 및 상태 관리.

#### 3.6.1 Fields

| Field | Type | Required | Example |
|-------|------|----------|---------|
| `table_number` | INTEGER | Yes | 1 |
| `table_name` | VARCHAR(100) | No | "Main Feature Table" |
| `rfid_device_id` | VARCHAR(100) | No | "RFID-001" |
| `is_active` | BOOLEAN | No | true |
| `is_streaming` | BOOLEAN | No | true |
| `max_seats` | INTEGER | No | 9 |
| `tournament_id` | UUID | No | (Soft FK) |

### 3.7 seating_assignments

실시간 좌석 배정 관리.

#### 3.7.1 Fields

| Field | Type | Required | Example |
|-------|------|----------|---------|
| `player_id` | UUID (FK) | Yes | - |
| `feature_table_id` | UUID (FK) | Yes | - |
| `seat_number` | INTEGER | Yes | 7 (1-10) |
| `is_current` | BOOLEAN | No | true |
| `assigned_at` | TIMESTAMPTZ | Auto | NOW() |
| `removed_at` | TIMESTAMPTZ | No | NULL |
| `removal_reason` | VARCHAR(100) | No | "eliminated" |

#### 3.7.2 Seating UI Design

```
┌─────────────────────────────────────────────────────────────────┐
│                  Feature Table Seating                           │
│                  Tournament: WSOP Main Event                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                        ┌─────────┐                              │
│                        │ Dealer  │                              │
│                        └─────────┘                              │
│                                                                  │
│       ┌─────┐                              ┌─────┐             │
│       │  1  │                              │  6  │             │
│       │     │  Phil Hellmuth               │     │  Empty      │
│       │ 2.5M│  [Assign] [Remove]           │     │  [Assign]   │
│       └─────┘                              └─────┘             │
│                                                                  │
│  ┌─────┐                                        ┌─────┐        │
│  │  2  │  Daniel Negreanu                       │  5  │ Empty  │
│  │ 4.5M│  [Remove]                              │     │[Assign]│
│  └─────┘                                        └─────┘        │
│                                                                  │
│       ┌─────┐                              ┌─────┐             │
│       │  3  │  Phil Ivey                   │  4  │ Empty       │
│       │ 8.7M│  [Remove]                    │     │ [Assign]    │
│       └─────┘                              └─────┘             │
│                                                                  │
│       ┌─────┐                              ┌─────┐             │
│       │  9  │  Erik Seidel                 │  8  │  Jason Koon │
│       │ 1.8M│  [Remove]                    │ 5.2M│  [Remove]   │
│       └─────┘                              └─────┘             │
│                                                                  │
│                        ┌─────┐                                  │
│                        │  7  │  Antonio Esfandiari             │
│                        │ 3.1M│  [Remove]                        │
│                        └─────┘                                  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Quick Assign: [Search player...                        ▼] │ │
│  │ To Seat: [1] [2] [3] [4] [5] [6] [7] [8] [9]              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Bulk Import Specifications

### 4.1 players_master.csv Format

```csv
name,nationality,display_name,wsop_bracelets,wsop_rings,total_earnings,is_key_player,hendon_mob_id,twitter_handle
Daniel Negreanu,CA,Kid Poker,6,2,45000000,true,daniel-negreanu,@RealKidPoker
Phil Ivey,US,,10,0,31000000,true,phil-ivey,
Phil Hellmuth,US,Poker Brat,16,0,28000000,true,phil-hellmuth,@phil_hellmuth
```

### 4.2 Import Script

```python
import csv
from pathlib import Path
from typing import Optional
from uuid import uuid4
from datetime import datetime

from supabase import create_client

class ManualDataImporter:
    def __init__(self, supabase_url: str, supabase_key: str):
        self.client = create_client(supabase_url, supabase_key)

    def import_players_master(self, file_path: Path) -> dict:
        """플레이어 마스터 벌크 임포트"""
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            players = []
            errors = []

            for i, row in enumerate(reader, start=2):
                try:
                    player = self._parse_player_row(row)
                    players.append(player)
                except ValueError as e:
                    errors.append(f"Row {i}: {str(e)}")

        if not players:
            return {'success': False, 'errors': errors}

        # Upsert (use name + nationality as natural key)
        for player in players:
            self.client.table('players_master') \
                .upsert(player, on_conflict='name,nationality') \
                .execute()

        return {
            'success': True,
            'imported': len(players),
            'errors': errors
        }

    def _parse_player_row(self, row: dict) -> dict:
        """CSV 행을 플레이어 레코드로 변환"""
        name = row.get('name', '').strip()
        nationality = row.get('nationality', '').strip().upper()

        if not name:
            raise ValueError("Missing required field: name")
        if not nationality or len(nationality) != 2:
            raise ValueError("Invalid nationality code")

        player = {
            'name': name,
            'nationality': nationality,
        }

        # Optional fields
        if row.get('display_name'):
            player['display_name'] = row['display_name'].strip()

        if row.get('wsop_bracelets'):
            player['wsop_bracelets'] = int(row['wsop_bracelets'])

        if row.get('wsop_rings'):
            player['wsop_rings'] = int(row['wsop_rings'])

        if row.get('total_earnings'):
            player['total_earnings'] = float(row['total_earnings'])

        if row.get('is_key_player'):
            player['is_key_player'] = row['is_key_player'].lower() == 'true'

        if row.get('hendon_mob_id'):
            player['hendon_mob_id'] = row['hendon_mob_id'].strip()

        if row.get('twitter_handle'):
            handle = row['twitter_handle'].strip()
            player['twitter_handle'] = handle
            player['social_links'] = {'twitter': handle}

        return player
```

### 4.3 venues.csv Format

```csv
name,short_name,city,country,timezone,capacity,table_count
Paris Las Vegas,Paris LV,Las Vegas,US,America/Los_Angeles,10000,500
Horseshoe Las Vegas,Horseshoe LV,Las Vegas,US,America/Los_Angeles,8000,400
Merit Royal Cyprus,Merit Cyprus,Kyrenia,CY,Europe/Nicosia,2000,100
```

---

## 5. API Specifications

### 5.1 REST API Endpoints

#### 5.1.1 Players Master

```
GET    /api/manual/players
       Query: ?search=phil&nationality=US&is_key_player=true&limit=50&offset=0

POST   /api/manual/players
       Body: { name, nationality, display_name?, ... }

GET    /api/manual/players/:id

PUT    /api/manual/players/:id
       Body: { name?, nationality?, display_name?, ... }

DELETE /api/manual/players/:id
```

#### 5.1.2 Seating Assignments

```
GET    /api/manual/feature-tables/:tableId/seating
       Response: [{ seat_number, player_id, player_name, chips, ... }]

POST   /api/manual/seating/assign
       Body: { feature_table_id, player_id, seat_number }

DELETE /api/manual/seating/:id
       Query: ?reason=eliminated|table_break|redraw|moved

POST   /api/manual/seating/bulk-assign
       Body: { feature_table_id, assignments: [{ player_id, seat_number }] }

POST   /api/manual/seating/clear-table
       Body: { feature_table_id, reason }
```

### 5.2 TypeScript Types

```typescript
// Players Master
interface PlayerMaster {
  id: string;
  name: string;
  nationality: string;  // ISO 3166-1 alpha-2
  display_name?: string;
  photo_url?: string;
  hendon_mob_id?: string;
  gpi_id?: string;
  wsop_player_id?: string;
  wsop_bracelets: number;
  wsop_rings: number;
  total_earnings: number;
  is_key_player: boolean;
  key_player_reason?: string;
  social_links?: Record<string, string>;
  created_at: string;
  updated_at: string;
}

interface CreatePlayerInput {
  name: string;
  nationality: string;
  display_name?: string;
  photo_url?: string;
  wsop_bracelets?: number;
  total_earnings?: number;
  is_key_player?: boolean;
}

// Seating Assignments
interface SeatingAssignment {
  id: string;
  player_id: string;
  feature_table_id: string;
  seat_number: number;  // 1-10
  is_current: boolean;
  assigned_at: string;
  removed_at?: string;
  removal_reason?: 'eliminated' | 'table_break' | 'redraw' | 'moved';
  chips_at_assignment?: number;
}

interface AssignSeatInput {
  feature_table_id: string;
  player_id: string;
  seat_number: number;
}
```

### 5.3 Supabase Client Usage

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(url, key);

// Create player
async function createPlayer(input: CreatePlayerInput): Promise<PlayerMaster> {
  const { data, error } = await supabase
    .from('players_master')
    .insert(input)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// Search players
async function searchPlayers(query: string): Promise<PlayerMaster[]> {
  const { data, error } = await supabase
    .from('players_master')
    .select('*')
    .or(`name.ilike.%${query}%,display_name.ilike.%${query}%`)
    .order('is_key_player', { ascending: false })
    .order('name')
    .limit(20);

  if (error) throw error;
  return data;
}

// Assign seat
async function assignSeat(input: AssignSeatInput): Promise<SeatingAssignment> {
  // First, check if seat is occupied
  const { data: existing } = await supabase
    .from('seating_assignments')
    .select('id')
    .eq('feature_table_id', input.feature_table_id)
    .eq('seat_number', input.seat_number)
    .eq('is_current', true)
    .single();

  if (existing) {
    throw new Error(`Seat ${input.seat_number} is already occupied`);
  }

  // Also check if player is already seated
  const { data: playerSeated } = await supabase
    .from('seating_assignments')
    .select('id, seat_number')
    .eq('feature_table_id', input.feature_table_id)
    .eq('player_id', input.player_id)
    .eq('is_current', true)
    .single();

  if (playerSeated) {
    throw new Error(`Player already seated at seat ${playerSeated.seat_number}`);
  }

  // Assign seat
  const { data, error } = await supabase
    .from('seating_assignments')
    .insert({
      ...input,
      is_current: true,
      assigned_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

// Remove from seat
async function removeFromSeat(
  assignmentId: string,
  reason: string
): Promise<void> {
  const { error } = await supabase
    .from('seating_assignments')
    .update({
      is_current: false,
      removed_at: new Date().toISOString(),
      removal_reason: reason,
    })
    .eq('id', assignmentId);

  if (error) throw error;
}
```

---

## 6. Data Quality

### 6.1 Duplicate Detection

```sql
-- 중복 플레이어 탐지
SELECT
    name,
    nationality,
    COUNT(*) as count,
    array_agg(id) as ids
FROM manual.players_master
GROUP BY name, nationality
HAVING COUNT(*) > 1;

-- 유사 이름 탐지 (Levenshtein)
SELECT
    p1.id as id1, p1.name as name1,
    p2.id as id2, p2.name as name2,
    levenshtein(LOWER(p1.name), LOWER(p2.name)) as distance
FROM manual.players_master p1
JOIN manual.players_master p2 ON p1.id < p2.id
WHERE levenshtein(LOWER(p1.name), LOWER(p2.name)) <= 3
ORDER BY distance;
```

### 6.2 Data Completeness Score

```sql
-- 데이터 완성도 점수 계산
CREATE OR REPLACE FUNCTION manual.calculate_completeness(p_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_score INTEGER := 0;
    v_player RECORD;
    v_profile RECORD;
BEGIN
    SELECT * INTO v_player FROM manual.players_master WHERE id = p_id;
    SELECT * INTO v_profile FROM manual.player_profiles WHERE player_id = p_id;

    -- Required fields (30 points)
    IF v_player.name IS NOT NULL THEN v_score := v_score + 15; END IF;
    IF v_player.nationality IS NOT NULL THEN v_score := v_score + 15; END IF;

    -- Photo (15 points)
    IF v_player.photo_url IS NOT NULL THEN v_score := v_score + 15; END IF;

    -- External IDs (15 points)
    IF v_player.hendon_mob_id IS NOT NULL THEN v_score := v_score + 5; END IF;
    IF v_player.gpi_id IS NOT NULL THEN v_score := v_score + 5; END IF;
    IF v_player.wsop_player_id IS NOT NULL THEN v_score := v_score + 5; END IF;

    -- Career stats (20 points)
    IF v_player.wsop_bracelets > 0 THEN v_score := v_score + 5; END IF;
    IF v_player.total_earnings > 0 THEN v_score := v_score + 10; END IF;
    IF v_player.biography IS NOT NULL THEN v_score := v_score + 5; END IF;

    -- Profile (20 points)
    IF v_profile IS NOT NULL THEN
        IF v_profile.birth_date IS NOT NULL THEN v_score := v_score + 5; END IF;
        IF v_profile.playing_style IS NOT NULL THEN v_score := v_score + 5; END IF;
        IF v_profile.biography IS NOT NULL THEN v_score := v_score + 10; END IF;
    END IF;

    RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- 완성도 업데이트 트리거
CREATE OR REPLACE FUNCTION manual.update_completeness_trigger()
RETURNS TRIGGER AS $$
BEGIN
    NEW.data_completeness := manual.calculate_completeness(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_completeness
    BEFORE INSERT OR UPDATE ON manual.players_master
    FOR EACH ROW
    EXECUTE FUNCTION manual.update_completeness_trigger();
```

### 6.3 Validation Rules

```python
from pydantic import BaseModel, validator, Field
from typing import Optional, List
import re

class CreatePlayerValidation(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    nationality: str = Field(..., regex=r'^[A-Z]{2}$')

    @validator('name')
    def validate_name(cls, v):
        # Check for suspicious patterns
        if re.match(r'^\d+$', v):
            raise ValueError('Name cannot be only numbers')
        if re.match(r'^[^a-zA-Z]+$', v):
            raise ValueError('Name must contain letters')
        if len(v.split()) < 2:
            # Single word names are allowed but flagged
            pass  # Could log warning
        return v.strip()

class SeatingValidation(BaseModel):
    feature_table_id: str
    player_id: str
    seat_number: int = Field(..., ge=1, le=10)

    @validator('seat_number')
    def validate_seat(cls, v):
        if v < 1 or v > 10:
            raise ValueError('Seat number must be between 1 and 10')
        return v
```

---

## 7. Workflows

### 7.1 New Player Registration

```
1. PA searches for player in existing database
   ↓ (not found)
2. PA clicks "Add New Player"
   ↓
3. PA enters required fields (name, nationality)
   ↓
4. System searches external sources (HendonMob, WSOP.com)
   ↓ (optional auto-fill)
5. PA reviews and confirms data
   ↓
6. PA uploads photo (or links external)
   ↓
7. PA saves record
   ↓
8. System generates UUID, sets timestamps
   ↓
9. Player available for seating assignments
```

### 7.2 Feature Table Setup

```
1. PD creates/activates Feature Table
   ↓
2. PD sets table_number, max_seats
   ↓
3. PD links to tournament (if applicable)
   ↓
4. PA assigns players to seats
   ↓
5. System validates:
   - Seat not already occupied
   - Player not already seated elsewhere on this table
   - Player exists in players_master
   ↓
6. Assignment created with timestamp
   ↓
7. UI updates in real-time (Supabase Realtime)
```

### 7.3 Player Elimination

```
1. Player is eliminated from tournament
   ↓
2. PA clicks "Remove" on player's seat
   ↓
3. PA selects reason: "eliminated"
   ↓
4. System updates seating_assignment:
   - is_current = false
   - removed_at = NOW()
   - removal_reason = 'eliminated'
   ↓
5. Seat becomes available
   ↓
6. (Optional) wsop_plus.player_instances updated
```

### 7.4 Table Break / Redraw

```
1. Table break announced
   ↓
2. PA clicks "Clear Table"
   ↓
3. PA selects reason: "table_break" or "redraw"
   ↓
4. All current assignments marked:
   - is_current = false
   - removed_at = NOW()
   - removal_reason = 'table_break'
   ↓
5. New assignments can be made
```

---

## 8. External Data Sources

### 8.1 HendonMob Integration

```python
import httpx
from bs4 import BeautifulSoup

class HendonMobClient:
    BASE_URL = "https://www.thehendonmob.com"

    async def search_player(self, name: str) -> list[dict]:
        """HendonMob에서 플레이어 검색"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.BASE_URL}/search",
                params={"q": name, "type": "player"}
            )
            # Parse HTML response
            soup = BeautifulSoup(response.text, 'html.parser')
            results = []
            # ... parse search results
            return results

    async def get_player_details(self, player_id: str) -> dict:
        """플레이어 상세 정보 조회"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.BASE_URL}/player.php/{player_id}"
            )
            soup = BeautifulSoup(response.text, 'html.parser')
            # ... parse player details
            return {
                'hendon_mob_id': player_id,
                'total_earnings': 0,  # parsed
                'wsop_bracelets': 0,  # parsed
                'photo_url': None,  # parsed
            }
```

### 8.2 Auto-Fill from External Sources

```typescript
async function autoFillPlayerData(name: string): Promise<Partial<PlayerMaster>> {
  // Search HendonMob
  const hendonResults = await searchHendonMob(name);

  if (hendonResults.length === 0) {
    return {};
  }

  // Get best match
  const match = hendonResults[0];

  return {
    hendon_mob_id: match.playerId,
    total_earnings: match.totalEarnings,
    wsop_bracelets: match.wsopBracelets,
    photo_url: match.photoUrl,
    nationality: match.country,
  };
}
```

---

## 9. Audit & History

### 9.1 Change History Table

```sql
CREATE TABLE manual.player_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES manual.players_master(id),
    changed_by VARCHAR(100),
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    change_type VARCHAR(20) NOT NULL,  -- 'create', 'update', 'delete'
    field_name VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    ip_address INET,
    user_agent TEXT
);

-- Audit trigger
CREATE OR REPLACE FUNCTION manual.audit_player_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO manual.player_changes (player_id, change_type, changed_by)
        VALUES (NEW.id, 'create', current_user);
    ELSIF TG_OP = 'UPDATE' THEN
        -- Log each changed field
        IF OLD.name IS DISTINCT FROM NEW.name THEN
            INSERT INTO manual.player_changes
            (player_id, change_type, field_name, old_value, new_value, changed_by)
            VALUES (NEW.id, 'update', 'name', OLD.name, NEW.name, current_user);
        END IF;
        -- ... repeat for other fields
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO manual.player_changes (player_id, change_type, changed_by)
        VALUES (OLD.id, 'delete', current_user);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_players
    AFTER INSERT OR UPDATE OR DELETE ON manual.players_master
    FOR EACH ROW
    EXECUTE FUNCTION manual.audit_player_changes();
```

### 9.2 Seating History View

```sql
CREATE VIEW manual.v_seating_history AS
SELECT
    sa.id,
    pm.name as player_name,
    pm.nationality,
    ft.table_number,
    sa.seat_number,
    sa.assigned_at,
    sa.removed_at,
    sa.removal_reason,
    EXTRACT(EPOCH FROM (COALESCE(sa.removed_at, NOW()) - sa.assigned_at)) / 60 as duration_minutes
FROM manual.seating_assignments sa
JOIN manual.players_master pm ON pm.id = sa.player_id
JOIN manual.feature_tables ft ON ft.id = sa.feature_table_id
ORDER BY sa.assigned_at DESC;
```

---

## 10. Monitoring

### 10.1 Data Quality Dashboard Query

```sql
-- 데이터 품질 대시보드
SELECT
    'Total Players' as metric,
    COUNT(*)::TEXT as value
FROM manual.players_master
UNION ALL
SELECT
    'Key Players',
    COUNT(*)::TEXT
FROM manual.players_master WHERE is_key_player
UNION ALL
SELECT
    'With Photo',
    COUNT(*)::TEXT
FROM manual.players_master WHERE photo_url IS NOT NULL
UNION ALL
SELECT
    'Avg Completeness',
    ROUND(AVG(data_completeness), 1)::TEXT || '%'
FROM manual.players_master
UNION ALL
SELECT
    'Low Completeness (<50%)',
    COUNT(*)::TEXT
FROM manual.players_master WHERE data_completeness < 50;
```

### 10.2 Active Seating Query

```sql
-- 현재 좌석 현황
SELECT
    ft.table_number,
    ft.table_name,
    COUNT(sa.id) FILTER (WHERE sa.is_current) as seated_count,
    ft.max_seats,
    array_agg(
        jsonb_build_object(
            'seat', sa.seat_number,
            'player', pm.name,
            'since', sa.assigned_at
        ) ORDER BY sa.seat_number
    ) FILTER (WHERE sa.is_current) as current_seating
FROM manual.feature_tables ft
LEFT JOIN manual.seating_assignments sa ON sa.feature_table_id = ft.id
LEFT JOIN manual.players_master pm ON pm.id = sa.player_id
WHERE ft.is_active
GROUP BY ft.id, ft.table_number, ft.table_name, ft.max_seats;
```

---

## Related Documents

- [PRD-0004: Database Schema](../../tasks/prds/0004-prd-caption-database-schema.md)
- [PRD-0007: 4-Schema Design](../../tasks/prds/0007-prd-4schema-database-design.md)
- [pokerGFX JSON Migration](./01-pokergfx-json-migration.md)
- [WSOP+ CSV Migration](./02-wsop-plus-csv-migration.md)
