# WSOP+ CSV Migration Guide

**Version**: 1.0.0 | **Target Schema**: `wsop_plus`

---

## 1. Overview

### 1.1 Purpose

WSOP+ Tournament Management System에서 내보낸 CSV 파일을 `wsop_plus` 스키마로 마이그레이션하는 가이드.

### 1.2 Data Flow

```
WSOP+ Tournament Management System
        |
        v
CSV Export (레벨 종료 시)
        |
        +-- tournament_data.csv
        +-- player_chips.csv
        +-- blind_structure.csv
        +-- payout_structure.csv
        +-- broadcast_schedule.csv
        |
        v CSV Parser
        |
wsop_plus.tournaments
        |
        +-- wsop_plus.blind_levels
        +-- wsop_plus.payouts
        +-- wsop_plus.player_instances
        +-- wsop_plus.schedules
```

### 1.3 Target Tables (5)

| Table | Description | Update Frequency |
|-------|-------------|------------------|
| `wsop_plus.tournaments` | 토너먼트 정보 | 레벨 종료 시 |
| `wsop_plus.blind_levels` | 블라인드 구조 | 이벤트 시작 전 |
| `wsop_plus.payouts` | 페이아웃 구조 | ITM 진입 시 |
| `wsop_plus.player_instances` | 참가자 칩/순위 | 레벨 종료 시 |
| `wsop_plus.schedules` | 방송 일정 | 수시 |

### 1.4 Data Scope

| Scope | Coverage |
|-------|----------|
| **All Tables** | 전체 토너먼트 테이블 (Feature + Other) |
| **Timing** | 배치 업데이트 (실시간 아님) |
| **Players** | 전체 참가자 칩 카운트 및 순위 |

---

## 2. Source CSV Formats

### 2.1 tournament_data.csv

```csv
tournament_number,name,buy_in,rake,starting_chips,current_level,remaining_players,registered_players,prize_pool,status
1,"WSOP Main Event",10000,930,60000,32,27,8569,85690000,running
2,"$1500 NLHE",1500,165,15000,18,145,2341,3511500,running
```

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `tournament_number` | INTEGER | Yes | 이벤트 번호 |
| `name` | VARCHAR | Yes | 토너먼트 이름 |
| `buy_in` | DECIMAL | Yes | 바이인 금액 |
| `rake` | DECIMAL | No | 레이크 |
| `starting_chips` | INTEGER | Yes | 시작 칩 |
| `current_level` | INTEGER | Yes | 현재 레벨 |
| `remaining_players` | INTEGER | Yes | 남은 플레이어 |
| `registered_players` | INTEGER | Yes | 등록 플레이어 |
| `prize_pool` | DECIMAL | No | 상금 풀 |
| `status` | VARCHAR | Yes | 상태 |

### 2.2 player_chips.csv

```csv
tournament_number,player_name,chips,table_number,seat_number,rank,is_eliminated
1,"Daniel Negreanu",4520000,15,3,12,false
1,"Phil Ivey",8750000,15,7,3,false
1,"Phil Hellmuth",0,,,189,true
```

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `tournament_number` | INTEGER | Yes | 토너먼트 번호 |
| `player_name` | VARCHAR | Yes | 플레이어 이름 |
| `chips` | BIGINT | Yes | 현재 칩 |
| `table_number` | INTEGER | No | 테이블 번호 |
| `seat_number` | INTEGER | No | 좌석 번호 |
| `rank` | INTEGER | No | 현재 순위 |
| `is_eliminated` | BOOLEAN | No | 탈락 여부 |

### 2.3 blind_structure.csv

```csv
tournament_number,level,small_blind,big_blind,ante,bb_ante,duration_minutes,is_break,break_name
1,1,100,200,0,0,60,false,
1,2,200,400,0,0,60,false,
1,3,300,600,600,600,60,false,
1,4,0,0,0,0,15,true,"Color Up"
```

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `tournament_number` | INTEGER | Yes | 토너먼트 번호 |
| `level` | INTEGER | Yes | 레벨 번호 |
| `small_blind` | INTEGER | Yes | 스몰 블라인드 |
| `big_blind` | INTEGER | Yes | 빅 블라인드 |
| `ante` | INTEGER | No | 앤티 |
| `bb_ante` | INTEGER | No | BB 앤티 |
| `duration_minutes` | INTEGER | Yes | 레벨 시간 (분) |
| `is_break` | BOOLEAN | No | 휴식 여부 |
| `break_name` | VARCHAR | No | 휴식 이름 |

### 2.4 payout_structure.csv

```csv
tournament_number,place_start,place_end,amount,percentage,is_bracelet
1,1,1,12100000,14.12,true
1,2,2,6500000,7.59,false
1,3,3,4500000,5.25,false
1,4,4,3500000,4.09,false
1,5,6,2500000,2.92,false
1,7,9,1750000,2.04,false
```

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `tournament_number` | INTEGER | Yes | 토너먼트 번호 |
| `place_start` | INTEGER | Yes | 시작 순위 |
| `place_end` | INTEGER | Yes | 종료 순위 |
| `amount` | DECIMAL | Yes | 상금 |
| `percentage` | DECIMAL | No | 상금 풀 비율 |
| `is_bracelet` | BOOLEAN | No | 브레이슬릿 여부 |

### 2.5 broadcast_schedule.csv

```csv
date,time_start,time_end,event_title,channel,tournament_number,is_live
2026-07-15,18:00,23:00,"Main Event Day 3 - Feature Table",WSOP+,1,true
2026-07-15,20:00,02:00,"Main Event Day 3 - Late Night",PokerGO,1,true
2026-07-16,14:00,18:00,"Main Event Day 3 - Replay",YouTube,1,false
```

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `date` | DATE | Yes | 방송 날짜 |
| `time_start` | TIME | Yes | 시작 시간 |
| `time_end` | TIME | No | 종료 시간 |
| `event_title` | VARCHAR | Yes | 이벤트 제목 |
| `channel` | VARCHAR | No | 채널 |
| `tournament_number` | INTEGER | No | 토너먼트 번호 |
| `is_live` | BOOLEAN | No | 라이브 여부 |

---

## 3. Field Mapping

### 3.1 tournaments Mapping

| CSV Column | DB Column | Type | Transform |
|------------|-----------|------|-----------|
| `tournament_number` | `tournament_number` | INTEGER | Direct |
| `name` | `name` | VARCHAR(255) | Direct |
| `buy_in` | `buy_in` | DECIMAL | Direct |
| `rake` | `rake` | DECIMAL | Default 0 |
| (computed) | `total_cost` | DECIMAL | GENERATED |
| `starting_chips` | `starting_chips` | INTEGER | Direct |
| `current_level` | `current_level` | INTEGER | Direct |
| `remaining_players` | `remaining_players` | INTEGER | Direct |
| `registered_players` | `registered_players` | INTEGER | Direct |
| `prize_pool` | `prize_pool` | DECIMAL | Default 0 |
| `status` | `status` | VARCHAR(20) | Normalize |
| (computed) | `avg_stack` | INTEGER | prize_pool / remaining |
| (computed) | `tournament_code` | VARCHAR(50) | Generate |

**Status Normalization**:

| CSV Value | DB Value |
|-----------|----------|
| `running`, `active`, `in_progress` | `running` |
| `scheduled`, `upcoming` | `scheduled` |
| `registration`, `reg_open` | `registration` |
| `paused`, `break` | `paused` |
| `final_table`, `ft` | `final_table` |
| `completed`, `finished`, `done` | `completed` |
| `cancelled`, `canceled` | `cancelled` |

### 3.2 blind_levels Mapping

| CSV Column | DB Column | Type | Transform |
|------------|-----------|------|-----------|
| `level` | `level_number` | INTEGER | Direct |
| `small_blind` | `small_blind` | INTEGER | Direct |
| `big_blind` | `big_blind` | INTEGER | Direct |
| `ante` | `ante` | INTEGER | Default 0 |
| `bb_ante` | `big_blind_ante` | INTEGER | Default 0 |
| (computed) | `blinds_display` | VARCHAR | GENERATED |
| `duration_minutes` | `duration_minutes` | INTEGER | Direct |
| `is_break` | `is_break` | BOOLEAN | Default false |
| `break_name` | `break_name` | VARCHAR(100) | Direct |
| (computed) | `is_current` | BOOLEAN | level == current_level |

### 3.3 payouts Mapping

| CSV Column | DB Column | Type | Transform |
|------------|-----------|------|-----------|
| `place_start` | `place_start` | INTEGER | Direct |
| `place_end` | `place_end` | INTEGER | Direct |
| (computed) | `place_display` | VARCHAR | GENERATED |
| `amount` | `amount` | DECIMAL | Direct |
| `percentage` | `percentage` | DECIMAL | Direct |
| (computed) | `formatted_amount` | VARCHAR | Format currency |
| `is_bracelet` | `is_bracelet` | BOOLEAN | Default false |
| (computed) | `is_current_bubble` | BOOLEAN | See bubble logic |

### 3.4 player_instances Mapping

| CSV Column | DB Column | Type | Transform |
|------------|-----------|------|-----------|
| `player_name` | `player_name` | VARCHAR(255) | Direct |
| (derived) | `player_display_name` | VARCHAR | First Last format |
| `chips` | `chips` | BIGINT | Direct |
| `table_number` | `table_number` | INTEGER | Direct |
| `seat_number` | `seat_number` | INTEGER | Direct |
| `rank` | `current_rank` | INTEGER | Direct |
| (computed) | `bb_count` | DECIMAL | chips / big_blind |
| `is_eliminated` | `is_eliminated` | BOOLEAN | Default false |
| (computed) | `eliminated_at` | TIMESTAMPTZ | NOW() if eliminated |
| (lookup) | `player_master_id` | UUID | Name matching |
| (computed) | `avg_stack_percentage` | DECIMAL | chips / avg_stack × 100 |

### 3.5 schedules Mapping

| CSV Column | DB Column | Type | Transform |
|------------|-----------|------|-----------|
| `date` | `date` | DATE | Direct |
| `time_start` | `time_start` | TIME | Direct |
| `time_end` | `time_end` | TIME | Direct |
| (computed) | `start_timestamp` | TIMESTAMPTZ | date + time + TZ |
| `event_title` | `event_title` | VARCHAR(255) | Direct |
| `channel` | `channel` | VARCHAR(100) | Direct |
| `is_live` | `is_live` | BOOLEAN | Default false |
| (computed) | `is_replay` | BOOLEAN | !is_live |
| (lookup) | `tournament_id` | UUID | tournament_number match |

---

## 4. Data Transformations

### 4.1 Tournament Code Generation

```python
def generate_tournament_code(
    tournament_number: int,
    name: str,
    year: int = None
) -> str:
    """토너먼트 코드 생성"""
    import re
    from datetime import datetime

    year = year or datetime.now().year

    # 이름에서 키워드 추출
    name_lower = name.lower()
    if 'main event' in name_lower:
        event_type = 'ME'
    elif 'championship' in name_lower:
        event_type = 'CHAMP'
    else:
        # 약어 생성: "No Limit Hold'em" -> "NLHE"
        words = re.findall(r'\b\w+', name)
        event_type = ''.join(w[0].upper() for w in words[:4])

    return f"WSOP_{year}_E{tournament_number}_{event_type}"

# Example: WSOP_2026_E1_ME (Main Event)
```

### 4.2 Chip Formatting

```python
def format_chips(chips: int) -> str:
    """칩 수를 표시 형식으로 변환"""
    if chips >= 1_000_000_000:
        return f"{chips / 1_000_000_000:.1f}B"
    elif chips >= 1_000_000:
        return f"{chips / 1_000_000:.1f}M"
    elif chips >= 1_000:
        return f"{chips / 1_000:.1f}K"
    else:
        return str(chips)

# Examples:
# 4520000 -> "4.5M"
# 875000000 -> "875.0M"
# 1250000000 -> "1.3B"
```

### 4.3 Bubble Calculation

```python
def calculate_bubble_line(
    remaining_players: int,
    payout_places: int
) -> dict:
    """버블 라인 계산"""
    bubble_line = payout_places + 1
    is_on_bubble = remaining_players == bubble_line
    is_itm = remaining_players <= payout_places

    return {
        'bubble_line': bubble_line,
        'is_on_bubble': is_on_bubble,
        'is_itm': is_itm,
        'players_to_bubble': max(0, remaining_players - payout_places)
    }
```

### 4.4 Average Stack Calculation

```python
def calculate_average_stack(
    remaining_players: int,
    starting_chips: int,
    registered_players: int,
    reentries: int = 0
) -> int:
    """평균 스택 계산"""
    total_chips = starting_chips * (registered_players + reentries)
    return total_chips // remaining_players if remaining_players > 0 else 0
```

### 4.5 BB Count Calculation

```python
def calculate_bb_count(chips: int, big_blind: int) -> float:
    """BB 카운트 계산"""
    if big_blind <= 0:
        return 0.0
    return round(chips / big_blind, 1)
```

---

## 5. Import Pipeline

### 5.1 Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     CSV Import Pipeline                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. File Detection                                               │
│     - Upload folder / FTP monitoring                            │
│     - File pattern: *_export_*.csv                              │
│     - Trigger: Manual upload / Scheduled sync                    │
│                                                                  │
│  2. File Type Detection                                          │
│     - tournament_data.csv → tournaments                          │
│     - player_chips.csv → player_instances                        │
│     - blind_structure.csv → blind_levels                         │
│     - payout_structure.csv → payouts                             │
│     - broadcast_schedule.csv → schedules                         │
│                                                                  │
│  3. Validation                                                   │
│     - Header validation                                          │
│     - Required fields check                                      │
│     - Data type validation                                       │
│                                                                  │
│  4. Tournament Resolution                                        │
│     - Find or create tournament by number/name                   │
│     - Generate tournament_code if new                            │
│                                                                  │
│  5. Upsert Processing                                            │
│     - tournaments: upsert by tournament_code                     │
│     - blind_levels: upsert by (tournament_id, level_number)      │
│     - payouts: upsert by (tournament_id, place_start, place_end) │
│     - player_instances: upsert by (tournament_id, player_name)   │
│     - schedules: insert (append mode)                            │
│                                                                  │
│  6. Post-Processing                                              │
│     - Update tournament statistics                               │
│     - Recalculate rankings                                       │
│     - Link player_master_id                                      │
│     - Update bubble status                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Python Import Script

```python
import csv
from pathlib import Path
from dataclasses import dataclass
from typing import Optional
from uuid import uuid4
from datetime import datetime

from supabase import create_client

@dataclass
class CSVFileType:
    TOURNAMENT = "tournament"
    PLAYERS = "players"
    BLINDS = "blinds"
    PAYOUTS = "payouts"
    SCHEDULE = "schedule"

class WSOPPlusImporter:
    def __init__(self, supabase_url: str, supabase_key: str):
        self.client = create_client(supabase_url, supabase_key)
        self._tournament_cache = {}

    def detect_file_type(self, file_path: Path) -> str:
        """CSV 파일 타입 감지"""
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            headers = next(reader)

        header_set = set(h.lower().strip() for h in headers)

        if {'buy_in', 'starting_chips', 'prize_pool'}.issubset(header_set):
            return CSVFileType.TOURNAMENT
        elif {'chips', 'table_number', 'seat_number'}.issubset(header_set):
            return CSVFileType.PLAYERS
        elif {'small_blind', 'big_blind', 'duration_minutes'}.issubset(header_set):
            return CSVFileType.BLINDS
        elif {'place_start', 'place_end', 'amount'}.issubset(header_set):
            return CSVFileType.PAYOUTS
        elif {'date', 'time_start', 'channel'}.issubset(header_set):
            return CSVFileType.SCHEDULE
        else:
            raise ValueError(f"Unknown CSV format: {headers}")

    def import_file(self, file_path: Path) -> dict:
        """CSV 파일 임포트"""
        file_type = self.detect_file_type(file_path)

        handlers = {
            CSVFileType.TOURNAMENT: self._import_tournaments,
            CSVFileType.PLAYERS: self._import_players,
            CSVFileType.BLINDS: self._import_blinds,
            CSVFileType.PAYOUTS: self._import_payouts,
            CSVFileType.SCHEDULE: self._import_schedules,
        }

        return handlers[file_type](file_path)

    def _import_tournaments(self, file_path: Path) -> dict:
        """토너먼트 데이터 임포트"""
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            tournaments = []

            for row in reader:
                tournament_number = int(row['tournament_number'])
                tournament_code = self._generate_code(
                    tournament_number, row['name']
                )

                tournament = {
                    'tournament_number': tournament_number,
                    'tournament_code': tournament_code,
                    'name': row['name'],
                    'buy_in': float(row['buy_in']),
                    'rake': float(row.get('rake', 0) or 0),
                    'starting_chips': int(row['starting_chips']),
                    'current_level': int(row['current_level']),
                    'remaining_players': int(row['remaining_players']),
                    'registered_players': int(row['registered_players']),
                    'prize_pool': float(row.get('prize_pool', 0) or 0),
                    'status': self._normalize_status(row['status']),
                    'last_sync_at': datetime.utcnow().isoformat(),
                }

                # Calculate avg_stack
                if tournament['remaining_players'] > 0:
                    total_chips = tournament['starting_chips'] * tournament['registered_players']
                    tournament['avg_stack'] = total_chips // tournament['remaining_players']

                tournaments.append(tournament)

        # Upsert
        result = self.client.table('tournaments') \
            .upsert(tournaments, on_conflict='tournament_code') \
            .execute()

        # Cache tournament IDs
        for t in result.data:
            self._tournament_cache[t['tournament_number']] = t['id']

        return {'type': 'tournaments', 'count': len(tournaments)}

    def _import_players(self, file_path: Path) -> dict:
        """플레이어 칩/순위 데이터 임포트"""
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            players = []

            for row in reader:
                tournament_number = int(row['tournament_number'])
                tournament_id = self._get_tournament_id(tournament_number)

                if not tournament_id:
                    continue

                player = {
                    'tournament_id': tournament_id,
                    'player_name': row['player_name'],
                    'chips': int(row['chips']),
                    'current_rank': int(row.get('rank', 0) or 0),
                    'is_eliminated': row.get('is_eliminated', 'false').lower() == 'true',
                    'last_sync_at': datetime.utcnow().isoformat(),
                }

                # Optional fields
                if row.get('table_number'):
                    player['table_number'] = int(row['table_number'])
                if row.get('seat_number'):
                    player['seat_number'] = int(row['seat_number'])

                # Try to match player_master_id
                player['player_master_id'] = self._find_player_master(row['player_name'])

                players.append(player)

        # Upsert by (tournament_id, player_name)
        for player in players:
            self.client.table('player_instances') \
                .upsert(player, on_conflict='tournament_id,player_name,entry_count') \
                .execute()

        return {'type': 'players', 'count': len(players)}

    def _import_blinds(self, file_path: Path) -> dict:
        """블라인드 구조 임포트"""
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            levels = []

            for row in reader:
                tournament_number = int(row['tournament_number'])
                tournament_id = self._get_tournament_id(tournament_number)

                if not tournament_id:
                    continue

                level = {
                    'tournament_id': tournament_id,
                    'level_number': int(row['level']),
                    'small_blind': int(row['small_blind']),
                    'big_blind': int(row['big_blind']),
                    'ante': int(row.get('ante', 0) or 0),
                    'big_blind_ante': int(row.get('bb_ante', 0) or 0),
                    'duration_minutes': int(row['duration_minutes']),
                    'is_break': row.get('is_break', 'false').lower() == 'true',
                    'break_name': row.get('break_name'),
                }

                levels.append(level)

        # Upsert
        for level in levels:
            self.client.table('blind_levels') \
                .upsert(level, on_conflict='tournament_id,level_number') \
                .execute()

        return {'type': 'blind_levels', 'count': len(levels)}

    def _import_payouts(self, file_path: Path) -> dict:
        """페이아웃 구조 임포트"""
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            payouts = []

            for row in reader:
                tournament_number = int(row['tournament_number'])
                tournament_id = self._get_tournament_id(tournament_number)

                if not tournament_id:
                    continue

                payout = {
                    'tournament_id': tournament_id,
                    'place_start': int(row['place_start']),
                    'place_end': int(row['place_end']),
                    'amount': float(row['amount']),
                    'percentage': float(row.get('percentage', 0) or 0),
                    'is_bracelet': row.get('is_bracelet', 'false').lower() == 'true',
                    'formatted_amount': self._format_currency(float(row['amount'])),
                }

                payouts.append(payout)

        # Upsert
        for payout in payouts:
            self.client.table('payouts') \
                .upsert(payout, on_conflict='tournament_id,place_start,place_end') \
                .execute()

        return {'type': 'payouts', 'count': len(payouts)}

    def _import_schedules(self, file_path: Path) -> dict:
        """방송 일정 임포트"""
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            schedules = []

            for row in reader:
                schedule = {
                    'date': row['date'],
                    'time_start': row['time_start'],
                    'time_end': row.get('time_end'),
                    'event_title': row['event_title'],
                    'channel': row.get('channel'),
                    'is_live': row.get('is_live', 'false').lower() == 'true',
                    'is_replay': row.get('is_live', 'false').lower() != 'true',
                }

                # Link tournament if specified
                if row.get('tournament_number'):
                    tournament_id = self._get_tournament_id(int(row['tournament_number']))
                    if tournament_id:
                        schedule['tournament_id'] = tournament_id

                schedules.append(schedule)

        # Insert (not upsert - schedules are append-only)
        result = self.client.table('schedules').insert(schedules).execute()

        return {'type': 'schedules', 'count': len(schedules)}

    def _get_tournament_id(self, tournament_number: int) -> Optional[str]:
        """토너먼트 ID 조회 (캐시 우선)"""
        if tournament_number in self._tournament_cache:
            return self._tournament_cache[tournament_number]

        result = self.client.table('tournaments') \
            .select('id') \
            .eq('tournament_number', tournament_number) \
            .execute()

        if result.data:
            self._tournament_cache[tournament_number] = result.data[0]['id']
            return result.data[0]['id']

        return None

    def _generate_code(self, number: int, name: str) -> str:
        """토너먼트 코드 생성"""
        import re
        year = datetime.now().year

        name_lower = name.lower()
        if 'main event' in name_lower:
            event_type = 'ME'
        elif 'championship' in name_lower:
            event_type = 'CHAMP'
        else:
            words = re.findall(r'\b\w+', name)
            event_type = ''.join(w[0].upper() for w in words[:4])

        return f"WSOP_{year}_E{number}_{event_type}"

    def _normalize_status(self, status: str) -> str:
        """상태 정규화"""
        status_map = {
            'running': 'running', 'active': 'running', 'in_progress': 'running',
            'scheduled': 'scheduled', 'upcoming': 'scheduled',
            'registration': 'registration', 'reg_open': 'registration',
            'paused': 'paused', 'break': 'paused',
            'final_table': 'final_table', 'ft': 'final_table',
            'completed': 'completed', 'finished': 'completed', 'done': 'completed',
            'cancelled': 'cancelled', 'canceled': 'cancelled',
        }
        return status_map.get(status.lower().strip(), 'scheduled')

    def _format_currency(self, amount: float) -> str:
        """통화 형식 포맷"""
        if amount >= 1_000_000:
            return f"${amount/1_000_000:.2f}M"
        elif amount >= 1_000:
            return f"${amount/1_000:.0f}K"
        else:
            return f"${amount:,.0f}"

    def _find_player_master(self, name: str) -> Optional[str]:
        """플레이어 마스터 ID 조회 (이름 매칭)"""
        result = self.client.table('players_master') \
            .select('id') \
            .ilike('name', name) \
            .execute()

        if result.data:
            return result.data[0]['id']
        return None
```

### 5.3 SQL Batch Import Function

```sql
CREATE OR REPLACE FUNCTION wsop_plus.import_player_chips_csv(
    p_tournament_id UUID,
    p_csv_data JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_row JSONB;
    v_count INTEGER := 0;
    v_current_bb INTEGER;
BEGIN
    -- Get current big blind for BB count calculation
    SELECT big_blind INTO v_current_bb
    FROM wsop_plus.blind_levels bl
    JOIN wsop_plus.tournaments t ON t.id = bl.tournament_id
    WHERE t.id = p_tournament_id AND bl.level_number = t.current_level;

    -- Process each row
    FOR v_row IN SELECT * FROM jsonb_array_elements(p_csv_data)
    LOOP
        INSERT INTO wsop_plus.player_instances (
            tournament_id,
            player_name,
            chips,
            table_number,
            seat_number,
            current_rank,
            is_eliminated,
            bb_count,
            last_sync_at
        )
        VALUES (
            p_tournament_id,
            v_row->>'player_name',
            (v_row->>'chips')::BIGINT,
            NULLIF(v_row->>'table_number', '')::INTEGER,
            NULLIF(v_row->>'seat_number', '')::INTEGER,
            NULLIF(v_row->>'rank', '')::INTEGER,
            COALESCE((v_row->>'is_eliminated')::BOOLEAN, FALSE),
            CASE WHEN v_current_bb > 0
                 THEN ROUND((v_row->>'chips')::NUMERIC / v_current_bb, 1)
                 ELSE 0 END,
            NOW()
        )
        ON CONFLICT (tournament_id, player_name, entry_count)
        DO UPDATE SET
            chips = EXCLUDED.chips,
            table_number = EXCLUDED.table_number,
            seat_number = EXCLUDED.seat_number,
            current_rank = EXCLUDED.current_rank,
            is_eliminated = EXCLUDED.is_eliminated,
            bb_count = EXCLUDED.bb_count,
            last_sync_at = NOW(),
            updated_at = NOW();

        v_count := v_count + 1;
    END LOOP;

    -- Update tournament avg_stack
    UPDATE wsop_plus.tournaments
    SET avg_stack = (
        SELECT ROUND(AVG(chips))
        FROM wsop_plus.player_instances
        WHERE tournament_id = p_tournament_id AND NOT is_eliminated
    ),
    remaining_players = (
        SELECT COUNT(*)
        FROM wsop_plus.player_instances
        WHERE tournament_id = p_tournament_id AND NOT is_eliminated
    ),
    updated_at = NOW()
    WHERE id = p_tournament_id;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;
```

---

## 6. Validation Rules

### 6.1 Required Fields by File Type

| File Type | Required Columns |
|-----------|------------------|
| tournament_data | tournament_number, name, buy_in, starting_chips, current_level, remaining_players, registered_players, status |
| player_chips | tournament_number, player_name, chips |
| blind_structure | tournament_number, level, small_blind, big_blind, duration_minutes |
| payout_structure | tournament_number, place_start, place_end, amount |
| broadcast_schedule | date, time_start, event_title |

### 6.2 Data Validation

```python
def validate_csv_data(file_type: str, rows: list[dict]) -> list[str]:
    """CSV 데이터 유효성 검사"""
    errors = []

    validators = {
        'tournament': validate_tournament_row,
        'players': validate_player_row,
        'blinds': validate_blind_row,
        'payouts': validate_payout_row,
        'schedule': validate_schedule_row,
    }

    validator = validators.get(file_type)
    if not validator:
        return [f"Unknown file type: {file_type}"]

    for i, row in enumerate(rows):
        row_errors = validator(row)
        for err in row_errors:
            errors.append(f"Row {i+1}: {err}")

    return errors

def validate_player_row(row: dict) -> list[str]:
    """플레이어 행 유효성 검사"""
    errors = []

    # Required fields
    if not row.get('player_name'):
        errors.append("Missing player_name")

    # Chips validation
    try:
        chips = int(row.get('chips', 0))
        if chips < 0:
            errors.append("chips must be non-negative")
    except ValueError:
        errors.append("Invalid chips value")

    # Seat validation
    seat = row.get('seat_number')
    if seat:
        try:
            seat_int = int(seat)
            if seat_int < 1 or seat_int > 10:
                errors.append("seat_number must be 1-10")
        except ValueError:
            errors.append("Invalid seat_number")

    return errors
```

---

## 7. Sync Strategies

### 7.1 Full Sync

전체 데이터 교체 (주로 blind_levels, payouts에 사용):

```python
def full_sync_blind_levels(tournament_id: str, levels: list[dict]):
    """블라인드 레벨 전체 동기화"""
    # Delete existing
    client.table('blind_levels') \
        .delete() \
        .eq('tournament_id', tournament_id) \
        .execute()

    # Insert all
    for level in levels:
        level['tournament_id'] = tournament_id
    client.table('blind_levels').insert(levels).execute()
```

### 7.2 Incremental Sync

변경분만 업데이트 (주로 player_instances에 사용):

```python
def incremental_sync_players(tournament_id: str, players: list[dict]):
    """플레이어 증분 동기화"""
    for player in players:
        player['tournament_id'] = tournament_id
        player['last_sync_at'] = datetime.utcnow().isoformat()

        client.table('player_instances') \
            .upsert(player, on_conflict='tournament_id,player_name,entry_count') \
            .execute()
```

### 7.3 Scheduled Sync

```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler

scheduler = AsyncIOScheduler()

@scheduler.scheduled_job('cron', minute='*/5')  # Every 5 minutes
async def sync_wsop_plus_data():
    """정기 동기화 작업"""
    importer = WSOPPlusImporter(url, key)

    # Check for new files
    for csv_file in Path('/import/wsop-plus/').glob('*.csv'):
        if is_new_or_modified(csv_file):
            result = importer.import_file(csv_file)
            log_import(csv_file, result)
            archive_file(csv_file)
```

---

## 8. Error Handling

### 8.1 Error Categories

| Category | Handling | Example |
|----------|----------|---------|
| **Parse Error** | Skip row, log warning | Invalid CSV format |
| **Validation Error** | Skip row, log warning | Missing required field |
| **FK Error** | Skip row, log error | Tournament not found |
| **Duplicate Error** | Upsert (update) | Same player in tournament |
| **Database Error** | Retry with backoff | Connection timeout |

### 8.2 Error Recovery

```python
from tenacity import retry, stop_after_attempt, wait_exponential

class WSOPPlusImporter:
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=60)
    )
    def _safe_upsert(self, table: str, data: dict, conflict_columns: str):
        """안전한 upsert (재시도 포함)"""
        return self.client.table(table) \
            .upsert(data, on_conflict=conflict_columns) \
            .execute()
```

---

## 9. Post-Import Processing

### 9.1 Rank Recalculation

```sql
CREATE OR REPLACE FUNCTION wsop_plus.recalculate_ranks(p_tournament_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Update ranks based on chip count
    WITH ranked AS (
        SELECT
            id,
            ROW_NUMBER() OVER (ORDER BY chips DESC) as new_rank,
            current_rank as old_rank
        FROM wsop_plus.player_instances
        WHERE tournament_id = p_tournament_id
          AND NOT is_eliminated
    )
    UPDATE wsop_plus.player_instances pi
    SET
        current_rank = ranked.new_rank,
        previous_rank = ranked.old_rank,
        rank_change = COALESCE(ranked.old_rank - ranked.new_rank, 0),
        updated_at = NOW()
    FROM ranked
    WHERE pi.id = ranked.id;

    -- Update chip leader
    UPDATE wsop_plus.tournaments
    SET
        chip_leader_name = (
            SELECT player_name FROM wsop_plus.player_instances
            WHERE tournament_id = p_tournament_id AND current_rank = 1
        ),
        chip_leader_chips = (
            SELECT chips FROM wsop_plus.player_instances
            WHERE tournament_id = p_tournament_id AND current_rank = 1
        ),
        updated_at = NOW()
    WHERE id = p_tournament_id;
END;
$$ LANGUAGE plpgsql;
```

### 9.2 Bubble Status Update

```sql
CREATE OR REPLACE FUNCTION wsop_plus.update_bubble_status(p_tournament_id UUID)
RETURNS VOID AS $$
DECLARE
    v_remaining INTEGER;
    v_places_paid INTEGER;
    v_bubble_place INTEGER;
BEGIN
    -- Get current state
    SELECT remaining_players, places_paid
    INTO v_remaining, v_places_paid
    FROM wsop_plus.tournaments
    WHERE id = p_tournament_id;

    -- Calculate bubble
    v_bubble_place := v_places_paid + 1;

    -- Reset all bubble flags
    UPDATE wsop_plus.payouts
    SET is_current_bubble = FALSE
    WHERE tournament_id = p_tournament_id;

    -- Set current bubble
    IF v_remaining = v_bubble_place THEN
        UPDATE wsop_plus.tournaments
        SET bubble_line = v_bubble_place
        WHERE id = p_tournament_id;

        UPDATE wsop_plus.payouts
        SET is_current_bubble = TRUE
        WHERE tournament_id = p_tournament_id
          AND place_start = v_places_paid;
    END IF;

    -- Check ITM
    IF v_remaining <= v_places_paid THEN
        UPDATE wsop_plus.tournaments
        SET is_itm = TRUE,
            itm_at = COALESCE(itm_at, NOW())
        WHERE id = p_tournament_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

---

## 10. Monitoring

### 10.1 Sync Health Query

```sql
-- 최근 동기화 상태 확인
SELECT
    t.name,
    t.remaining_players,
    t.last_sync_at,
    NOW() - t.last_sync_at as sync_age,
    (SELECT COUNT(*) FROM wsop_plus.player_instances
     WHERE tournament_id = t.id AND NOT is_eliminated) as player_count
FROM wsop_plus.tournaments t
WHERE t.status = 'running'
ORDER BY t.last_sync_at DESC;
```

### 10.2 Data Quality Check

```sql
-- 데이터 품질 확인
SELECT
    t.name,
    t.remaining_players as reported_remaining,
    COUNT(pi.id) FILTER (WHERE NOT pi.is_eliminated) as actual_remaining,
    t.avg_stack as reported_avg,
    ROUND(AVG(pi.chips) FILTER (WHERE NOT pi.is_eliminated)) as actual_avg
FROM wsop_plus.tournaments t
LEFT JOIN wsop_plus.player_instances pi ON pi.tournament_id = t.id
WHERE t.status = 'running'
GROUP BY t.id, t.name, t.remaining_players, t.avg_stack
HAVING t.remaining_players != COUNT(pi.id) FILTER (WHERE NOT pi.is_eliminated);
```

---

## Related Documents

- [PRD-0004: Database Schema](../../tasks/prds/0004-prd-caption-database-schema.md)
- [PRD-0007: 4-Schema Design](../../tasks/prds/0007-prd-4schema-database-design.md)
- [pokerGFX JSON Migration](./01-pokergfx-json-migration.md)
- [Manual Input Migration](./03-manual-input-migration.md)
