# pokerGFX JSON Migration Guide

**Version**: 1.0.0 | **Target Schema**: `json`

---

## 1. Overview

### 1.1 Purpose

pokerGFX RFID 시스템에서 생성되는 JSON 파일을 `json` 스키마로 마이그레이션하는 가이드.

### 1.2 Data Flow

```
Feature Table RFID Scanner
        |
        v
pokerGFX Software (3.2+)
        |
        v
JSON File (638961999170907267.json)
        |
        v JSON Parser
        |
json.gfx_sessions
        |
        +-- json.hands
              |
              +-- json.hand_players
              +-- json.hand_actions
              +-- json.hand_cards
              +-- json.hand_results
```

### 1.3 Target Tables (6)

| Table | Description | Records per Session |
|-------|-------------|---------------------|
| `json.gfx_sessions` | 세션 메타데이터 | 1 |
| `json.hands` | 핸드별 정보 | ~50-200 |
| `json.hand_players` | 핸드-플레이어 상태 | hands × 9 |
| `json.hand_actions` | 액션 로그 | hands × ~20 |
| `json.hand_cards` | 카드 정보 | hands × ~25 |
| `json.hand_results` | 핸드 결과 | hands × winners |

---

## 2. Source Data Format

### 2.1 JSON Root Structure

```json
{
  "ID": 638961999170907267,
  "CreatedDateTimeUTC": "2025-10-16T08:25:17.0907267Z",
  "EventTitle": "WSOP Main Event Day 3",
  "Type": "FEATURE_TABLE",
  "SoftwareVersion": "PokerGFX 3.2",
  "Payouts": [0,0,0,0,0,0,0,0,0,0],
  "Hands": [...]
}
```

### 2.2 Hand Object

```json
{
  "HandNum": 2,
  "GameVariant": "HOLDEM",
  "GameClass": "FLOP",
  "BetStructure": "NOLIMIT",
  "Duration": "PT2M56.2628165S",
  "StartDateTimeUTC": "2025-10-16T08:28:43.2539856Z",
  "NumBoards": 1,
  "RunItNumTimes": 1,
  "Players": [...],
  "Events": [...],
  "FlopDrawBlinds": {...}
}
```

### 2.3 Player Object

```json
{
  "PlayerNum": 7,
  "Name": "Phil Ivey",
  "LongName": "Phillip Dennis Ivey Jr.",
  "StartStackAmt": 9000000,
  "EndStackAmt": 12500000,
  "CumulativeWinningsAmt": 3500000,
  "HoleCards": ["as", "kh"],
  "SittingOut": false,
  "EliminationRank": -1,
  "VPIPPercent": 28.5,
  "PreFlopRaisePercent": 22.3,
  "AggressionFrequencyPercent": 45.2,
  "WentToShowDownPercent": 31.0
}
```

### 2.4 Event Object (Action)

```json
{
  "EventType": "RAISE",
  "PlayerNum": 5,
  "BetAmt": 180000,
  "Pot": 370000,
  "BoardCards": null,
  "BoardNum": 0,
  "DateTimeUTC": "2025-10-16T08:29:15.123Z",
  "NumCardsDrawn": 0
}
```

---

## 3. Field Mapping

### 3.1 gfx_sessions Mapping

| JSON Field | DB Column | Type | Transform |
|------------|-----------|------|-----------|
| `ID` | `gfx_id` | BIGINT | Direct |
| `CreatedDateTimeUTC` | `created_at_gfx` | TIMESTAMPTZ | ISO 8601 parse |
| `EventTitle` | `event_title` | VARCHAR(255) | Direct |
| `Type` | `table_type` | VARCHAR(50) | Direct |
| `SoftwareVersion` | `software_version` | VARCHAR(50) | Direct |
| `Payouts` | `payouts` | JSONB | Direct |
| (file path) | `source_file` | VARCHAR(500) | Path normalize |
| (computed) | `source_checksum` | VARCHAR(64) | SHA-256 |
| (counted) | `total_hands` | INTEGER | `Hands.length` |

### 3.2 hands Mapping

| JSON Field | DB Column | Type | Transform |
|------------|-----------|------|-----------|
| `HandNum` | `hand_number` | INTEGER | Direct |
| `GameVariant` | `game_variant` | VARCHAR(20) | Direct |
| `GameClass` | `game_class` | VARCHAR(20) | Direct |
| `BetStructure` | `bet_structure` | VARCHAR(20) | Direct |
| `Duration` | `duration` | INTERVAL | ISO 8601 Duration |
| `StartDateTimeUTC` | `started_at` | TIMESTAMPTZ | ISO 8601 parse |
| `NumBoards` | `num_boards` | INTEGER | Direct |
| `RunItNumTimes` | `run_it_num_times` | INTEGER | Direct |
| `FlopDrawBlinds.ButtonPlayerNum` | `button_seat` | INTEGER | Direct |
| `FlopDrawBlinds.SmallBlindAmt` | `small_blind_amount` | DECIMAL | Direct |
| `FlopDrawBlinds.BigBlindAmt` | `big_blind_amount` | DECIMAL | Direct |
| `FlopDrawBlinds.BlindLevel` | `level_number` | INTEGER | Direct |
| (computed from Events) | `pot_size` | DECIMAL | Max pot from actions |
| (computed from Players) | `player_count` | INTEGER | Active players count |

### 3.3 hand_players Mapping

| JSON Field | DB Column | Type | Transform |
|------------|-----------|------|-----------|
| `PlayerNum` | `seat_number` | INTEGER | Direct |
| `Name` | `player_name` | VARCHAR(255) | Direct |
| `LongName` | `player_long_name` | VARCHAR(500) | Direct |
| `StartStackAmt` | `start_stack` | BIGINT | Direct |
| `EndStackAmt` | `end_stack` | BIGINT | Direct |
| (computed) | `stack_delta` | BIGINT | GENERATED |
| `CumulativeWinningsAmt` | `cumulative_winnings` | BIGINT | Direct |
| `HoleCards` | `hole_cards` | JSONB | Card conversion |
| `HoleCards[0]` | `hole_card_1` | VARCHAR(3) | Card conversion |
| `HoleCards[1]` | `hole_card_2` | VARCHAR(3) | Card conversion |
| `SittingOut` | `sitting_out` | BOOLEAN | Direct |
| `EliminationRank` | `elimination_rank` | INTEGER | -1 → NULL |
| `VPIPPercent` | `vpip_percent` | DECIMAL | Direct |
| `PreFlopRaisePercent` | `pfr_percent` | DECIMAL | Direct |
| `AggressionFrequencyPercent` | `aggression_percent` | DECIMAL | Direct |
| `WentToShowDownPercent` | `wtsd_percent` | DECIMAL | Direct |

### 3.4 hand_actions Mapping

| JSON Field | DB Column | Type | Transform |
|------------|-----------|------|-----------|
| (index) | `action_order` | INTEGER | Array index |
| (derived) | `street` | VARCHAR(20) | From EventType sequence |
| `EventType` | `event_type` | VARCHAR(30) | Direct |
| `EventType` | `action` | VARCHAR(20) | Normalize (see below) |
| `PlayerNum` | `seat_number` | INTEGER | Direct |
| `BetAmt` | `bet_amount` | DECIMAL | Direct |
| `Pot` | `pot_size_after` | DECIMAL | Direct |
| `BoardCards` | `board_cards` | JSONB | Card conversion |
| `BoardNum` | `board_num` | INTEGER | Direct |
| `DateTimeUTC` | `action_time` | TIMESTAMPTZ | ISO 8601 parse |
| `NumCardsDrawn` | `num_cards_drawn` | INTEGER | Direct |

**EventType → action Mapping**:

| GFX EventType | DB action |
|---------------|-----------|
| `FOLD` | `fold` |
| `CALL` | `call` |
| `CHECK` | `check` |
| `RAISE` | `raise` |
| `BET` | `bet` |
| `ALL_IN` | `all-in` |
| `SHOWDOWN` | `showdown` |
| `BOARD_CARD` | (skip, use board_cards) |

---

## 4. Data Transformations

### 4.1 Card Format Conversion

pokerGFX와 DB 간 카드 형식 변환:

```
GFX Format    → DB Format
─────────────────────────
as            → As
kh            → Kh
10d           → Td        (10 → T)
jc            → Jc
```

**Python Implementation**:

```python
def convert_gfx_card(gfx_card: str) -> str:
    """pokerGFX 카드 형식을 DB 형식으로 변환"""
    rank = gfx_card[:-1].upper()
    suit = gfx_card[-1].lower()
    if rank == '10':
        rank = 'T'
    return f"{rank}{suit}"

def convert_hole_cards(gfx_cards: list[str]) -> str:
    """홀카드 배열을 정규화된 문자열로 변환"""
    return ''.join(convert_gfx_card(c) for c in gfx_cards)
```

**SQL Function**:

```sql
CREATE OR REPLACE FUNCTION json.convert_gfx_card(gfx_card TEXT)
RETURNS TEXT AS $$
DECLARE
    rank TEXT;
    suit TEXT;
BEGIN
    rank := UPPER(LEFT(gfx_card, LENGTH(gfx_card) - 1));
    suit := LOWER(RIGHT(gfx_card, 1));
    IF rank = '10' THEN
        rank := 'T';
    END IF;
    RETURN rank || suit;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 4.2 Duration Conversion

ISO 8601 Duration → PostgreSQL INTERVAL:

```
GFX: "PT2M56.2628165S"
 ↓
DB: INTERVAL '2 minutes 56.2628165 seconds'
```

```python
import re
from datetime import timedelta

def parse_iso_duration(duration: str) -> timedelta:
    """ISO 8601 Duration을 timedelta로 변환"""
    match = re.match(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:([\d.]+)S)?', duration)
    if not match:
        return timedelta()

    hours = int(match.group(1) or 0)
    minutes = int(match.group(2) or 0)
    seconds = float(match.group(3) or 0)

    return timedelta(hours=hours, minutes=minutes, seconds=seconds)
```

### 4.3 Street Detection

액션 시퀀스에서 Street 판별:

```python
def detect_street(events: list[dict], current_index: int) -> str:
    """EventType 시퀀스로 현재 Street 판별"""
    board_card_count = 0

    for i in range(current_index + 1):
        if events[i].get('EventType') == 'BOARD_CARD':
            cards = events[i].get('BoardCards', [])
            if cards:
                board_card_count = len(cards)

    if board_card_count == 0:
        return 'preflop'
    elif board_card_count == 3:
        return 'flop'
    elif board_card_count == 4:
        return 'turn'
    elif board_card_count == 5:
        return 'river'
    else:
        return 'unknown'
```

---

## 5. Import Pipeline

### 5.1 Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Import Pipeline                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. File Detection                                               │
│     - Watch folder: /gfx-output/                                │
│     - File pattern: *.json                                       │
│     - Trigger: New file / Modified file                          │
│                                                                  │
│  2. Validation                                                   │
│     - JSON schema validation                                     │
│     - Required fields check                                      │
│     - Duplicate check (gfx_id)                                   │
│                                                                  │
│  3. Checksum                                                     │
│     - SHA-256 hash calculation                                   │
│     - Skip if unchanged                                          │
│                                                                  │
│  4. Parse & Transform                                            │
│     - Card format conversion                                     │
│     - Duration parsing                                           │
│     - Street detection                                           │
│                                                                  │
│  5. Database Insert                                              │
│     - Transaction-based                                          │
│     - gfx_sessions first                                         │
│     - hands with FK                                              │
│     - hand_players, hand_actions, hand_cards, hand_results       │
│                                                                  │
│  6. Post-Processing                                              │
│     - Update statistics                                          │
│     - Link player_master_id (fuzzy match)                        │
│     - Calculate grades                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Python Import Script

```python
import json
import hashlib
from pathlib import Path
from datetime import datetime
from uuid import uuid4

from supabase import create_client

class PokerGFXImporter:
    def __init__(self, supabase_url: str, supabase_key: str):
        self.client = create_client(supabase_url, supabase_key)

    def import_file(self, file_path: Path) -> str:
        """JSON 파일을 DB로 임포트"""

        # 1. Read & Parse
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 2. Calculate checksum
        checksum = hashlib.sha256(
            json.dumps(data, sort_keys=True).encode()
        ).hexdigest()

        # 3. Check duplicate
        existing = self.client.table('gfx_sessions') \
            .select('id, source_checksum') \
            .eq('gfx_id', data['ID']) \
            .execute()

        if existing.data:
            if existing.data[0]['source_checksum'] == checksum:
                return existing.data[0]['id']  # Skip unchanged
            # Update existing session
            session_id = existing.data[0]['id']
            self._delete_session_data(session_id)
        else:
            session_id = str(uuid4())

        # 4. Insert session
        session = self._create_session(data, file_path, checksum, session_id)
        self.client.table('gfx_sessions').upsert(session).execute()

        # 5. Import hands
        for hand_data in data.get('Hands', []):
            self._import_hand(session_id, hand_data)

        return session_id

    def _create_session(self, data: dict, file_path: Path,
                        checksum: str, session_id: str) -> dict:
        return {
            'id': session_id,
            'gfx_id': data['ID'],
            'event_title': data.get('EventTitle'),
            'table_type': data.get('Type', 'FEATURE_TABLE'),
            'software_version': data.get('SoftwareVersion'),
            'payouts': data.get('Payouts', []),
            'source_file': str(file_path),
            'source_checksum': checksum,
            'total_hands': len(data.get('Hands', [])),
            'created_at_gfx': data.get('CreatedDateTimeUTC'),
            'import_status': 'processing'
        }

    def _import_hand(self, session_id: str, hand_data: dict):
        """핸드 데이터 임포트"""
        hand_id = str(uuid4())

        # Hand record
        hand = {
            'id': hand_id,
            'gfx_session_id': session_id,
            'hand_number': hand_data['HandNum'],
            'game_variant': hand_data.get('GameVariant', 'HOLDEM'),
            'game_class': hand_data.get('GameClass', 'FLOP'),
            'bet_structure': hand_data.get('BetStructure', 'NOLIMIT'),
            'started_at': hand_data.get('StartDateTimeUTC'),
            'num_boards': hand_data.get('NumBoards', 1),
            'run_it_num_times': hand_data.get('RunItNumTimes', 1),
            'player_count': len([p for p in hand_data.get('Players', [])
                                if not p.get('SittingOut', False)])
        }

        # Add blinds info
        blinds = hand_data.get('FlopDrawBlinds', {})
        if blinds:
            hand.update({
                'button_seat': blinds.get('ButtonPlayerNum'),
                'small_blind_seat': blinds.get('SmallBlindPlayerNum'),
                'big_blind_seat': blinds.get('BigBlindPlayerNum'),
                'small_blind_amount': blinds.get('SmallBlindAmt'),
                'big_blind_amount': blinds.get('BigBlindAmt'),
                'level_number': blinds.get('BlindLevel')
            })

        self.client.table('hands').insert(hand).execute()

        # Import players
        for player_data in hand_data.get('Players', []):
            self._import_hand_player(hand_id, player_data)

        # Import actions
        for idx, event_data in enumerate(hand_data.get('Events', [])):
            self._import_hand_action(hand_id, idx, event_data,
                                     hand_data.get('Events', []))

    def _import_hand_player(self, hand_id: str, player_data: dict):
        """플레이어 데이터 임포트"""
        hole_cards = player_data.get('HoleCards', [])

        player = {
            'id': str(uuid4()),
            'hand_id': hand_id,
            'seat_number': player_data['PlayerNum'],
            'player_name': player_data.get('Name', 'Unknown'),
            'player_long_name': player_data.get('LongName'),
            'start_stack': player_data.get('StartStackAmt', 0),
            'end_stack': player_data.get('EndStackAmt', 0),
            'cumulative_winnings': player_data.get('CumulativeWinningsAmt', 0),
            'hole_cards': [self._convert_card(c) for c in hole_cards] if hole_cards else None,
            'hole_cards_normalized': self._convert_hole_cards(hole_cards),
            'sitting_out': player_data.get('SittingOut', False),
            'vpip_percent': player_data.get('VPIPPercent'),
            'pfr_percent': player_data.get('PreFlopRaisePercent'),
            'aggression_percent': player_data.get('AggressionFrequencyPercent'),
            'wtsd_percent': player_data.get('WentToShowDownPercent'),
        }

        if hole_cards:
            for i, card in enumerate(hole_cards[:4]):
                player[f'hole_card_{i+1}'] = self._convert_card(card)

        elim_rank = player_data.get('EliminationRank', -1)
        if elim_rank > 0:
            player['elimination_rank'] = elim_rank
            player['is_eliminated'] = True

        self.client.table('hand_players').insert(player).execute()

    def _convert_card(self, gfx_card: str) -> str:
        """GFX 카드 형식을 DB 형식으로 변환"""
        rank = gfx_card[:-1].upper()
        suit = gfx_card[-1].lower()
        if rank == '10':
            rank = 'T'
        return f"{rank}{suit}"

    def _convert_hole_cards(self, cards: list) -> str | None:
        if not cards:
            return None
        return ''.join(self._convert_card(c) for c in cards)
```

### 5.3 SQL Batch Import Function

```sql
CREATE OR REPLACE FUNCTION json.import_gfx_session(
    gfx_data JSONB,
    p_tournament_id UUID DEFAULT NULL,
    p_feature_table_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_session_id UUID;
    v_hand JSONB;
    v_hand_id UUID;
BEGIN
    -- Generate session ID
    v_session_id := gen_random_uuid();

    -- Insert session
    INSERT INTO json.gfx_sessions (
        id, gfx_id, event_title, table_type, software_version,
        payouts, created_at_gfx, tournament_id, feature_table_id,
        total_hands, import_status
    )
    VALUES (
        v_session_id,
        (gfx_data->>'ID')::BIGINT,
        gfx_data->>'EventTitle',
        COALESCE(gfx_data->>'Type', 'FEATURE_TABLE'),
        gfx_data->>'SoftwareVersion',
        COALESCE(gfx_data->'Payouts', '[]'::JSONB),
        (gfx_data->>'CreatedDateTimeUTC')::TIMESTAMPTZ,
        p_tournament_id,
        p_feature_table_id,
        jsonb_array_length(COALESCE(gfx_data->'Hands', '[]'::JSONB)),
        'processing'
    );

    -- Import each hand
    FOR v_hand IN SELECT * FROM jsonb_array_elements(gfx_data->'Hands')
    LOOP
        v_hand_id := json.import_hand(v_session_id, v_hand);
    END LOOP;

    -- Update session status
    UPDATE json.gfx_sessions
    SET import_status = 'complete',
        updated_at = NOW()
    WHERE id = v_session_id;

    RETURN v_session_id;
END;
$$ LANGUAGE plpgsql;
```

---

## 6. Validation Rules

### 6.1 Required Fields

| Field | Required | Validation |
|-------|----------|------------|
| `ID` | Yes | Must be valid Windows FileTime (positive BIGINT) |
| `Hands` | Yes | Must be array |
| `Hands[].HandNum` | Yes | Must be positive integer |
| `Hands[].Players` | Yes | Must have at least 2 players |
| `Hands[].Players[].PlayerNum` | Yes | Must be 1-10 |
| `Hands[].Players[].Name` | Yes | Non-empty string |
| `Hands[].Players[].StartStackAmt` | Yes | Non-negative integer |

### 6.2 Data Integrity Checks

```python
def validate_gfx_data(data: dict) -> list[str]:
    """GFX JSON 데이터 유효성 검사"""
    errors = []

    # Root validation
    if 'ID' not in data:
        errors.append("Missing required field: ID")
    elif not isinstance(data['ID'], int) or data['ID'] <= 0:
        errors.append("Invalid ID format")

    if 'Hands' not in data:
        errors.append("Missing required field: Hands")
        return errors

    # Hand validation
    for i, hand in enumerate(data['Hands']):
        prefix = f"Hand[{i}]"

        if 'HandNum' not in hand:
            errors.append(f"{prefix}: Missing HandNum")

        if 'Players' not in hand:
            errors.append(f"{prefix}: Missing Players")
            continue

        if len(hand['Players']) < 2:
            errors.append(f"{prefix}: Less than 2 players")

        # Player validation
        for j, player in enumerate(hand['Players']):
            p_prefix = f"{prefix}.Player[{j}]"

            seat = player.get('PlayerNum')
            if seat is None or seat < 1 or seat > 10:
                errors.append(f"{p_prefix}: Invalid PlayerNum")

            if not player.get('Name'):
                errors.append(f"{p_prefix}: Missing Name")

    return errors
```

---

## 7. Error Handling

### 7.1 Error Categories

| Category | Handling | Example |
|----------|----------|---------|
| **Parse Error** | Skip file, log error | Invalid JSON syntax |
| **Validation Error** | Skip file, log error | Missing required field |
| **Duplicate Error** | Check checksum, update or skip | Same gfx_id |
| **Database Error** | Rollback transaction, retry | Connection timeout |
| **Transform Error** | Use default, log warning | Invalid card format |

### 7.2 Error Logging

```python
import logging
from dataclasses import dataclass
from enum import Enum

class ErrorSeverity(Enum):
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"

@dataclass
class ImportError:
    file_path: str
    severity: ErrorSeverity
    category: str
    message: str
    context: dict = None

class ImportErrorHandler:
    def __init__(self):
        self.errors: list[ImportError] = []
        self.logger = logging.getLogger('gfx_import')

    def add_error(self, error: ImportError):
        self.errors.append(error)

        log_msg = f"[{error.category}] {error.file_path}: {error.message}"
        if error.context:
            log_msg += f" | Context: {error.context}"

        if error.severity == ErrorSeverity.WARNING:
            self.logger.warning(log_msg)
        elif error.severity == ErrorSeverity.ERROR:
            self.logger.error(log_msg)
        else:
            self.logger.critical(log_msg)

    def get_summary(self) -> dict:
        return {
            'total': len(self.errors),
            'warnings': len([e for e in self.errors
                           if e.severity == ErrorSeverity.WARNING]),
            'errors': len([e for e in self.errors
                         if e.severity == ErrorSeverity.ERROR]),
            'critical': len([e for e in self.errors
                           if e.severity == ErrorSeverity.CRITICAL])
        }
```

---

## 8. Performance Optimization

### 8.1 Batch Insert

```python
# Instead of individual inserts
for player in players:
    client.table('hand_players').insert(player).execute()

# Use batch insert
client.table('hand_players').insert(players).execute()
```

### 8.2 Index Usage

```sql
-- 중복 체크용 인덱스
CREATE UNIQUE INDEX idx_gfx_sessions_gfx_id ON json.gfx_sessions(gfx_id);

-- 조회 최적화 인덱스
CREATE INDEX idx_hands_gfx_session_id ON json.hands(gfx_session_id);
CREATE INDEX idx_hand_players_hand_id ON json.hand_players(hand_id);
CREATE INDEX idx_hand_actions_hand_id ON json.hand_actions(hand_id);
```

### 8.3 Connection Pooling

```python
from supabase import create_client
import asyncio

class PooledImporter:
    def __init__(self, url: str, key: str, pool_size: int = 5):
        self.clients = [create_client(url, key) for _ in range(pool_size)]
        self.available = asyncio.Queue()
        for client in self.clients:
            self.available.put_nowait(client)

    async def get_client(self):
        return await self.available.get()

    async def release_client(self, client):
        await self.available.put(client)
```

---

## 9. Monitoring

### 9.1 Import Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `import_duration_seconds` | 파일당 임포트 시간 | > 30s |
| `import_error_rate` | 오류 발생률 | > 5% |
| `records_per_second` | 초당 레코드 삽입 | < 100 |
| `queue_depth` | 대기 중인 파일 수 | > 10 |

### 9.2 Health Check Query

```sql
-- 최근 임포트 상태 확인
SELECT
    import_status,
    COUNT(*) as count,
    MAX(updated_at) as last_update
FROM json.gfx_sessions
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY import_status;

-- 임포트 오류 확인
SELECT
    id,
    source_file,
    import_status,
    import_errors
FROM json.gfx_sessions
WHERE import_status = 'error'
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

---

## 10. Rollback Procedure

### 10.1 Session Rollback

```sql
-- 세션 및 관련 데이터 삭제 (CASCADE)
DELETE FROM json.gfx_sessions WHERE id = :session_id;

-- 또는 특정 gfx_id로 삭제
DELETE FROM json.gfx_sessions WHERE gfx_id = :gfx_id;
```

### 10.2 Full Schema Reset

```sql
-- WARNING: 모든 데이터 삭제
TRUNCATE TABLE json.hand_results CASCADE;
TRUNCATE TABLE json.hand_cards CASCADE;
TRUNCATE TABLE json.hand_actions CASCADE;
TRUNCATE TABLE json.hand_players CASCADE;
TRUNCATE TABLE json.hands CASCADE;
TRUNCATE TABLE json.gfx_sessions CASCADE;
```

---

## Related Documents

- [PRD-0004: Database Schema](../../tasks/prds/0004-prd-caption-database-schema.md)
- [PRD-0007: 4-Schema Design](../../tasks/prds/0007-prd-4schema-database-design.md)
- [WSOP+ CSV Migration](./02-wsop-plus-csv-migration.md)
- [Manual Input Migration](./03-manual-input-migration.md)
