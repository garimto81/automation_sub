# PRD-0007 Part 3: Cross-Schema Mapping

## 1. 스키마 간 관계 개요

4개 스키마는 **Soft FK**와 **Cross-Schema View**로 연결됩니다.

```
┌─────────┐                           ┌───────────┐
│   ae    │                           │   json    │
│         │                           │           │
│ layer_  │                           │ gfx_      │
│ data_   │──source_schema────────────│ sessions  │
│ mappings│  source_table             │           │
│         │  source_column            │ hands     │
│         │                           │           │
│         │                           │ hand_     │
│         │                           │ players   │
└────┬────┘                           └─────┬─────┘
     │                                      │
     │  ┌────────────────────────────────┐  │
     │  │      Soft FK 참조 관계         │  │
     │  └────────────────────────────────┘  │
     │                                      │
     │  tournament_id ─────────────────┐    │ tournament_id
     │  player_master_id ──────────┐   │    │ feature_table_id
     │  feature_table_id ─────┐    │   │    │ player_master_id
     │                        │    │   │    │
     ▼                        ▼    ▼   ▼    ▼
┌─────────────────────────────────────────────────┐
│                    manual                        │
│                                                 │
│  players_master ◀─────── player_master_id       │
│  feature_tables ◀─────── feature_table_id       │
│  events         ◀─────── event_id               │
│  venues         ◀─────── venue_id               │
│                                                 │
└─────────────────────────────────────────────────┘
                         ▲
                         │
┌─────────────────────────────────────────────────┐
│                  wsop_plus                       │
│                                                 │
│  tournaments ────────────── tournament_id ◀──   │
│  player_instances ───────── player_master_id    │
│  schedules ──────────────── event_id            │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 2. Soft FK 전략

### 2.1 정의

**Soft FK**: 외래 키 제약 조건 없이 UUID 컬럼으로 참조하는 방식

```sql
-- Hard FK (제약 조건 있음)
tournament_id UUID REFERENCES wsop_plus.tournaments(id) ON DELETE CASCADE

-- Soft FK (제약 조건 없음, 주석으로 문서화)
tournament_id UUID,  -- Soft FK → wsop_plus.tournaments
```

### 2.2 Soft FK를 사용하는 이유

| 이유 | 설명 |
|------|------|
| **스키마 독립성** | 스키마별 독립 배포/마이그레이션 가능 |
| **삭제 유연성** | 참조 대상 삭제 시 오류 없이 NULL 유지 |
| **성능** | FK 검증 오버헤드 제거 |
| **순환 참조 방지** | 크로스 스키마 순환 참조 문제 해결 |

### 2.3 Soft FK 목록

| 소스 테이블 | 컬럼 | 대상 테이블 |
|------------|------|------------|
| **json.gfx_sessions** | tournament_id | wsop_plus.tournaments |
| **json.gfx_sessions** | feature_table_id | manual.feature_tables |
| **json.gfx_sessions** | event_id | manual.events |
| **json.hand_players** | player_master_id | manual.players_master |
| **wsop_plus.tournaments** | event_id | manual.events |
| **wsop_plus.tournaments** | venue_id | manual.venues |
| **wsop_plus.player_instances** | player_master_id | manual.players_master |
| **wsop_plus.player_instances** | feature_table_id | manual.feature_tables |
| **wsop_plus.schedules** | event_id | manual.events |
| **wsop_plus.schedules** | venue_id | manual.venues |
| **manual.feature_tables** | tournament_id | wsop_plus.tournaments |
| **ae.layer_data_mappings** | source_schema + source_table | 동적 참조 |

---

## 3. ae.layer_data_mappings 매핑

### 3.1 매핑 구조

`ae.layer_data_mappings` 테이블은 AE 레이어와 데이터 소스를 연결:

```sql
CREATE TABLE ae.layer_data_mappings (
    layer_id UUID UNIQUE NOT NULL,      -- 대상 레이어
    source_schema VARCHAR(50) NOT NULL, -- 'json', 'wsop_plus', 'manual'
    source_table VARCHAR(100) NOT NULL, -- 'players_master', 'hands'
    source_column VARCHAR(100) NOT NULL,-- 'name', 'chips'
    source_path TEXT,                   -- JSONB 경로: 'payouts[0].amount'
    transform_type VARCHAR(50),         -- 'format_number', 'uppercase'
    transform_config JSONB DEFAULT '{}'
);
```

### 3.2 매핑 예시

| 레이어 | source_schema | source_table | source_column | transform |
|--------|---------------|--------------|---------------|-----------|
| Name 1 | manual | players_master | display_name | uppercase |
| Chips 1 | wsop_plus | player_instances | chips | format_number |
| BBs 1 | wsop_plus | player_instances | bb_count | - |
| Flag 1 | manual | players_master | nationality | flag_path |
| Blinds | wsop_plus | blind_levels | blinds_display | - |
| Hole Card 1 | json | hand_players | hole_card_1 | - |
| Pot Size | json | hands | pot_size | format_chips |
| Winner | json | hand_results | player_name | uppercase |

### 3.3 매핑 SQL 예시

```sql
-- Feature Table Leaderboard 매핑
INSERT INTO ae.layer_data_mappings (layer_id, source_schema, source_table, source_column, transform_type)
VALUES
  -- Name 레이어들
  ('uuid-name-1', 'manual', 'players_master', 'display_name', 'uppercase'),
  ('uuid-name-2', 'manual', 'players_master', 'display_name', 'uppercase'),

  -- Chips 레이어들
  ('uuid-chips-1', 'wsop_plus', 'player_instances', 'chips', 'format_number'),
  ('uuid-chips-2', 'wsop_plus', 'player_instances', 'chips', 'format_number'),

  -- Flag 레이어들 (국적 → 플래그 이미지 경로)
  ('uuid-flag-1', 'manual', 'players_master', 'nationality', 'flag_path');
```

---

## 4. Cross-Schema Views

### 4.1 v_feature_table_leaderboard

Feature Table의 현재 리더보드:

```sql
CREATE VIEW public.v_feature_table_leaderboard AS
SELECT
    -- Feature Table 정보
    ft.id AS feature_table_id,
    ft.table_name,
    ft.table_number,

    -- 플레이어 마스터 정보
    pm.id AS player_master_id,
    pm.name,
    pm.display_name,
    pm.nationality,
    pm.photo_url,
    pm.wsop_bracelets,

    -- 토너먼트 인스턴스 정보
    pi.chips,
    pi.current_rank,
    pi.bb_count,
    pi.rank_change,

    -- 좌석 정보
    sa.seat_number

FROM manual.feature_tables ft
JOIN manual.seating_assignments sa
    ON ft.id = sa.feature_table_id AND sa.is_current = TRUE
JOIN manual.players_master pm
    ON sa.player_id = pm.id
LEFT JOIN wsop_plus.player_instances pi
    ON pi.player_master_id = pm.id
    AND pi.tournament_id::text = ft.tournament_id::text
WHERE ft.is_active = TRUE
ORDER BY ft.table_number, pi.chips DESC;
```

### 4.2 v_unified_players

플레이어 통합 뷰 (마스터 + 인스턴스):

```sql
CREATE VIEW public.v_unified_players AS
SELECT
    pm.id AS player_master_id,
    pm.name,
    pm.display_name,
    pm.nationality,
    pm.photo_url,
    pm.wsop_bracelets,
    pm.total_earnings,

    pi.id AS player_instance_id,
    pi.tournament_id,
    pi.chips,
    pi.current_rank,
    pi.bb_count,
    pi.is_eliminated,

    t.name AS tournament_name,
    t.current_level,
    t.buy_in,
    t.prize_pool

FROM manual.players_master pm
LEFT JOIN wsop_plus.player_instances pi
    ON pi.player_master_id = pm.id
LEFT JOIN wsop_plus.tournaments t
    ON pi.tournament_id = t.id;
```

### 4.3 v_unified_hands

핸드 통합 뷰 (GFX + 마스터 플레이어):

```sql
CREATE VIEW public.v_unified_hands AS
SELECT
    h.id AS hand_id,
    h.hand_number,
    h.game_variant,
    h.pot_size,
    h.grade,
    h.is_premium,
    h.started_at,
    h.completed_at,

    hp.seat_number,
    hp.player_name AS gfx_player_name,
    hp.start_stack,
    hp.end_stack,
    hp.stack_delta,
    hp.hole_cards_normalized,
    hp.is_winner,

    -- 마스터 플레이어 매칭
    pm.id AS player_master_id,
    pm.display_name,
    pm.nationality,
    pm.photo_url

FROM json.hands h
JOIN json.hand_players hp ON h.id = hp.hand_id
LEFT JOIN manual.players_master pm
    ON LOWER(pm.name) = LOWER(hp.player_name);
```

### 4.4 v_current_blind_level

현재 블라인드 레벨:

```sql
CREATE VIEW public.v_current_blind_level AS
SELECT
    t.id AS tournament_id,
    t.name AS tournament_name,
    bl.level_number,
    bl.small_blind,
    bl.big_blind,
    bl.ante,
    bl.blinds_display,
    bl.duration_minutes,
    bl.started_at,
    bl.ends_at,
    bl.time_remaining_seconds
FROM wsop_plus.tournaments t
JOIN wsop_plus.blind_levels bl
    ON t.id = bl.tournament_id AND bl.is_current = TRUE
WHERE t.status IN ('running', 'final_table');
```

---

## 5. 26개 자막 유형 매핑

### 5.1 자막 → 스키마 매핑 매트릭스

| # | 자막 유형 | ae | json | wsop_plus | manual |
|---|----------|:--:|:----:|:---------:|:------:|
| 1 | Tournament Leaderboard | ✓ | | ✓ | ✓ |
| 2 | Feature Table LB | ✓ | ✓ | ✓ | ✓ |
| 3 | Mini Chip Counts | ✓ | ✓ | ✓ | ✓ |
| 4 | Payouts | ✓ | | ✓ | |
| 5 | Mini Payouts | ✓ | | ✓ | |
| 6 | Player Profile | ✓ | | ✓ | ✓ |
| 7 | Player Intro Card | ✓ | | | ✓ |
| 8 | At Risk | ✓ | | ✓ | ✓ |
| 9 | Elimination Banner | ✓ | | ✓ | ✓ |
| 10 | Commentator Profile | ✓ | | | ✓ |
| 11 | Heads-Up Comparison | ✓ | ✓ | ✓ | ✓ |
| 12 | Chip Flow | ✓ | ✓ | | |
| 13 | Chip Comparison | ✓ | ✓ | | |
| 14 | Chips In Play | ✓ | | ✓ | |
| 15 | VPIP Stats | ✓ | ✓ | | |
| 16 | Chip Stack Bar | ✓ | | ✓ | ✓ |
| 17 | Broadcast Schedule | ✓ | | ✓ | ✓ |
| 18 | Event Info | ✓ | | ✓ | ✓ |
| 19 | Venue/Location | ✓ | | | ✓ |
| 20 | Tournament Info | ✓ | | ✓ | ✓ |
| 21 | Event Name | ✓ | | | ✓ |
| 22 | Blind Level | ✓ | | ✓ | |
| 23 | L-Bar (Standard) | ✓ | ✓ | ✓ | |
| 24 | L-Bar (Regi Open) | ✓ | | ✓ | |
| 25 | L-Bar (Regi Close) | ✓ | | ✓ | |
| 26 | Transition/Stinger | ✓ | | | |

### 5.2 데이터 소스 우선순위

동일 필드에 여러 소스가 있을 때:

```
1. json (실시간) - Feature Table 전용
2. wsop_plus (배치) - Other Tables + 토너먼트 정보
3. manual (수동) - 프로필, 보정
```

예: 플레이어 칩 카운트
```
Feature Table → json.hand_players.end_stack (실시간)
Other Tables → wsop_plus.player_instances.chips (배치)
```

---

## 6. 데이터 조인 패턴

### 6.1 Feature Table Leaderboard 조회

```sql
-- Feature Table의 현재 리더보드 (순위순)
SELECT
    sa.seat_number,
    pm.display_name,
    pm.nationality,
    COALESCE(hp.end_stack, pi.chips) AS chips,
    pi.current_rank,
    pi.bb_count
FROM manual.feature_tables ft
JOIN manual.seating_assignments sa ON ft.id = sa.feature_table_id
JOIN manual.players_master pm ON sa.player_id = pm.id
LEFT JOIN wsop_plus.player_instances pi ON pi.player_master_id = pm.id
LEFT JOIN json.gfx_sessions gs ON gs.feature_table_id = ft.id
LEFT JOIN json.hands h ON h.gfx_session_id = gs.id
    AND h.hand_number = (SELECT MAX(hand_number) FROM json.hands WHERE gfx_session_id = gs.id)
LEFT JOIN json.hand_players hp ON hp.hand_id = h.id
    AND LOWER(hp.player_name) = LOWER(pm.name)
WHERE ft.is_active = TRUE
ORDER BY COALESCE(hp.end_stack, pi.chips) DESC;
```

### 6.2 핸드 결과 + 플레이어 정보

```sql
-- 특정 핸드의 결과와 플레이어 마스터 정보
SELECT
    h.hand_number,
    h.pot_size,
    h.grade,
    hr.seat_number,
    hr.player_name AS gfx_name,
    hr.is_winner,
    hr.won_amount,
    hr.hand_rank,
    pm.display_name,
    pm.nationality,
    pm.photo_url,
    pm.wsop_bracelets
FROM json.hand_results hr
JOIN json.hands h ON hr.hand_id = h.id
LEFT JOIN manual.players_master pm
    ON LOWER(pm.name) = LOWER(hr.player_name)
WHERE h.id = 'hand-uuid'
ORDER BY hr.is_winner DESC, hr.won_amount DESC;
```

### 6.3 플레이어 이름 매칭 전략

GFX player_name과 마스터 데이터 매칭:

```sql
-- 매칭 우선순위
-- 1. 정확히 일치 (대소문자 무시)
-- 2. display_name 일치
-- 3. alternative_names JSONB 포함 여부

SELECT pm.*
FROM manual.players_master pm
WHERE
    LOWER(pm.name) = LOWER('DANIEL NEGREANU')
    OR LOWER(pm.display_name) = LOWER('DANIEL NEGREANU')
    OR pm.alternate_names @> '"DANIEL NEGREANU"'::jsonb
LIMIT 1;
```

---

## 7. 데이터 무결성 보장

### 7.1 애플리케이션 레벨 검증

Soft FK이므로 애플리케이션에서 검증:

```python
async def validate_soft_fk(
    session: AsyncSession,
    source_id: UUID,
    target_schema: str,
    target_table: str
) -> bool:
    """Soft FK 유효성 검증"""
    if source_id is None:
        return True  # NULL은 허용

    query = text(f"SELECT EXISTS(SELECT 1 FROM {target_schema}.{target_table} WHERE id = :id)")
    result = await session.execute(query, {"id": source_id})
    return result.scalar()
```

### 7.2 정기 정합성 검사

```sql
-- 고아 레코드 검출 (참조 대상 없는 Soft FK)
SELECT
    'json.gfx_sessions' AS source_table,
    COUNT(*) AS orphan_count
FROM json.gfx_sessions gs
WHERE gs.tournament_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM wsop_plus.tournaments t WHERE t.id = gs.tournament_id
  )

UNION ALL

SELECT
    'wsop_plus.player_instances' AS source_table,
    COUNT(*) AS orphan_count
FROM wsop_plus.player_instances pi
WHERE pi.player_master_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM manual.players_master pm WHERE pm.id = pi.player_master_id
  );
```

---

## 다음 파트

→ [Part 4: Data Flow](04-data-flow.md)
