# Data Migration Guides

**Version**: 1.0.0 | **Last Updated**: 2026-01-09

WSOP Broadcast Graphics 시스템의 3가지 데이터 소스별 마이그레이션 가이드 인덱스.

---

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Data Source Architecture                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │  pokerGFX JSON  │  │   WSOP+ CSV     │  │  Manual Input   │             │
│  │                 │  │                 │  │                 │             │
│  │  Feature Table  │  │  All Tables     │  │  Master Data    │             │
│  │  RFID 실시간    │  │  배치 업데이트  │  │  수동 입력      │             │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘             │
│           │                    │                    │                       │
│           ▼                    ▼                    ▼                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   json schema   │  │ wsop_plus schema│  │  manual schema  │             │
│  │   (6 tables)    │  │   (5 tables)    │  │   (7 tables)    │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Migration Guides

| # | Guide | Schema | Tables | Update Frequency |
|:-:|-------|--------|:------:|------------------|
| 1 | [pokerGFX JSON](./01-pokergfx-json-migration.md) | `json` | 6 | ~1초 (실시간) |
| 2 | [WSOP+ CSV](./02-wsop-plus-csv-migration.md) | `wsop_plus` | 5 | 레벨 종료 시 |
| 3 | [Manual Input](./03-manual-input-migration.md) | `manual` | 7 | 수동 |

---

## Quick Reference

### 1. pokerGFX JSON → `json` Schema

**용도**: Feature Table RFID 데이터 실시간 수집

| Table | Description |
|-------|-------------|
| `gfx_sessions` | GFX 세션 메타데이터 |
| `hands` | 핸드별 정보 |
| `hand_players` | 핸드-플레이어 상태 |
| `hand_actions` | 액션 로그 (Event Sourcing) |
| `hand_cards` | 카드 정보 |
| `hand_results` | 핸드 결과 |

**Key Transformations**:
- 카드 형식: `as` → `As`, `10d` → `Td`
- Duration: `PT2M56S` → `INTERVAL '2 minutes 56 seconds'`

```python
# Quick Start
from importer import PokerGFXImporter
importer = PokerGFXImporter(url, key)
session_id = importer.import_file(Path("session.json"))
```

---

### 2. WSOP+ CSV → `wsop_plus` Schema

**용도**: 토너먼트 운영 데이터 배치 동기화

| Table | Description |
|-------|-------------|
| `tournaments` | 토너먼트 정보 |
| `blind_levels` | 블라인드 구조 |
| `payouts` | 페이아웃 구조 |
| `player_instances` | 참가자 칩/순위 |
| `schedules` | 방송 일정 |

**CSV File Types**:
- `tournament_data.csv` → tournaments
- `player_chips.csv` → player_instances
- `blind_structure.csv` → blind_levels
- `payout_structure.csv` → payouts
- `broadcast_schedule.csv` → schedules

```python
# Quick Start
from importer import WSOPPlusImporter
importer = WSOPPlusImporter(url, key)
result = importer.import_file(Path("player_chips.csv"))
```

---

### 3. Manual Input → `manual` Schema

**용도**: 운영팀 수동 입력 마스터 데이터

| Table | Description |
|-------|-------------|
| `players_master` | 플레이어 마스터 레지스트리 |
| `player_profiles` | 상세 프로필 (1:1) |
| `commentators` | 코멘테이터 정보 |
| `venues` | 장소/베뉴 정보 |
| `events` | 이벤트/시리즈 정보 |
| `feature_tables` | Feature Table 설정 |
| `seating_assignments` | 좌석 배정 (실시간) |

**Input Methods**:
- Admin Web UI (폼 입력)
- REST API
- Bulk Import (CSV)

```typescript
// Quick Start - Assign Seat
await supabase.from('seating_assignments').insert({
  feature_table_id: tableId,
  player_id: playerId,
  seat_number: 7,
  is_current: true
});
```

---

## Data Source Comparison

| Aspect | pokerGFX JSON | WSOP+ CSV | Manual Input |
|--------|---------------|-----------|--------------|
| **Scope** | Feature Table Only | All Tables | Master Data |
| **Frequency** | ~1초 | 레벨 종료 | On-demand |
| **Automation** | Full | Semi | Manual |
| **Data Type** | Hands, Actions, Cards | Chips, Ranks, Payouts | Profiles, Seating |
| **담당자** | System | TD/Staff | PA/PD |

---

## Cross-Schema References

스키마 간 Soft FK 관계:

```
json.gfx_sessions.tournament_id      → wsop_plus.tournaments.id
json.gfx_sessions.feature_table_id   → manual.feature_tables.id
json.hand_players.player_master_id   → manual.players_master.id

wsop_plus.tournaments.event_id       → manual.events.id
wsop_plus.player_instances.player_master_id → manual.players_master.id

manual.seating_assignments.player_id → manual.players_master.id
manual.feature_tables.tournament_id  → wsop_plus.tournaments.id
```

---

## Implementation Priority

### Phase 1: Schema Setup
1. [ ] `manual` 스키마 테이블 생성
2. [ ] `wsop_plus` 스키마 테이블 생성
3. [ ] `json` 스키마 테이블 생성

### Phase 2: Manual Data Entry
1. [ ] Admin UI 개발
2. [ ] 플레이어 마스터 초기 데이터 입력
3. [ ] 베뉴, 이벤트 설정

### Phase 3: CSV Import
1. [ ] CSV 파서 구현
2. [ ] 토너먼트 데이터 임포트
3. [ ] 자동 동기화 스케줄러

### Phase 4: Real-time Integration
1. [ ] pokerGFX JSON 파서 구현
2. [ ] File watcher 설정
3. [ ] 실시간 데이터 파이프라인

---

## Common Operations

### Import pokerGFX Session

```bash
# Python script
python scripts/import_gfx_session.py --file session.json

# SQL function
SELECT json.import_gfx_session(
    '{"ID": 638961999170907267, ...}'::JSONB,
    'tournament-uuid',
    'feature-table-uuid'
);
```

### Sync WSOP+ Data

```bash
# Import all CSV files from folder
python scripts/sync_wsop_plus.py --folder /data/wsop-export/

# Import specific file
python scripts/sync_wsop_plus.py --file player_chips.csv
```

### Bulk Import Players

```bash
# CSV import
python scripts/import_players.py --file players_master.csv

# API
curl -X POST /api/manual/players/bulk \
  -H "Content-Type: multipart/form-data" \
  -F "file=@players_master.csv"
```

---

## Validation & Monitoring

### Data Quality Check

```sql
-- 전체 데이터 현황
SELECT
    'json.gfx_sessions' as table_name, COUNT(*) as count FROM json.gfx_sessions
UNION ALL SELECT 'json.hands', COUNT(*) FROM json.hands
UNION ALL SELECT 'wsop_plus.tournaments', COUNT(*) FROM wsop_plus.tournaments
UNION ALL SELECT 'wsop_plus.player_instances', COUNT(*) FROM wsop_plus.player_instances
UNION ALL SELECT 'manual.players_master', COUNT(*) FROM manual.players_master
UNION ALL SELECT 'manual.seating_assignments', COUNT(*) FROM manual.seating_assignments;
```

### Recent Import Status

```sql
-- 최근 임포트 상태
SELECT
    'json' as schema,
    MAX(created_at) as last_import,
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '1 hour') as last_hour
FROM json.gfx_sessions
UNION ALL
SELECT
    'wsop_plus',
    MAX(last_sync_at),
    COUNT(*) FILTER (WHERE last_sync_at > NOW() - INTERVAL '1 hour')
FROM wsop_plus.tournaments;
```

---

## Related Documents

| Document | Description |
|----------|-------------|
| [PRD-0004](../../tasks/prds/0004-prd-caption-database-schema.md) | Database Schema 설계 |
| [PRD-0007](../../tasks/prds/0007-prd-4schema-database-design.md) | 4-Schema 아키텍처 |
| [PRD-0003](../../tasks/prds/0003-prd-caption-workflow.md) | Caption Workflow |

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-09 | Initial release - 3 migration guides |
