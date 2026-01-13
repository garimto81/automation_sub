# PRD-0007 Part 5: Implementation Guide

## 1. Migration 파일 구조

### 1.1 파일 목록

```
supabase/migrations/
├── 20260110000000_create_schemas.sql        # 4개 스키마 생성
├── 20260110000100_ae_schema_tables.sql      # ae 스키마 7개 테이블
├── 20260110000200_json_schema_tables.sql    # json 스키마 6개 테이블
├── 20260110000300_wsop_plus_schema_tables.sql  # wsop_plus 5개 테이블
├── 20260110000400_manual_schema_tables.sql  # manual 스키마 7개 테이블
├── 20260110000500_indexes.sql               # 전체 인덱스 (90+)
├── 20260110000600_functions_triggers.sql    # 함수 7개 + 트리거 20+
└── 20260110000700_rls_policies.sql          # RLS 정책
```

### 1.2 실행 순서

Migration 파일은 **타임스탬프 순서**로 자동 실행됩니다:

```
1. create_schemas       → 스키마 네임스페이스 생성
2. ae_schema_tables     → ae.* 테이블 생성
3. json_schema_tables   → json.* 테이블 생성
4. wsop_plus_tables     → wsop_plus.* 테이블 생성
5. manual_tables        → manual.* 테이블 생성
6. indexes              → 인덱스 생성
7. functions_triggers   → 함수/트리거 생성
8. rls_policies         → RLS 활성화 및 정책 적용
```

---

## 2. 적용 방법

### 2.1 로컬 개발 환경

```powershell
# 1. Supabase CLI 시작
cd C:\claude\automation_sub
supabase start

# 2. Migration 적용 (로컬 DB 초기화 + 적용)
supabase db reset

# 3. 상태 확인
supabase db status
```

### 2.2 원격 Supabase 프로젝트

```powershell
# 1. 프로젝트 연결
supabase link --project-ref YOUR_PROJECT_REF

# 2. Migration 푸시
supabase db push

# 3. 확인
supabase db diff
```

### 2.3 수동 적용 (SQL 직접 실행)

```powershell
# 파일 순서대로 실행
psql -h localhost -p 54322 -U postgres -d postgres \
  -f supabase/migrations/20260110000000_create_schemas.sql \
  -f supabase/migrations/20260110000100_ae_schema_tables.sql \
  -f supabase/migrations/20260110000200_json_schema_tables.sql \
  -f supabase/migrations/20260110000300_wsop_plus_schema_tables.sql \
  -f supabase/migrations/20260110000400_manual_schema_tables.sql \
  -f supabase/migrations/20260110000500_indexes.sql \
  -f supabase/migrations/20260110000600_functions_triggers.sql \
  -f supabase/migrations/20260110000700_rls_policies.sql
```

---

## 3. 검증 체크리스트

### 3.1 스키마 생성 확인

```sql
-- 4개 스키마 존재 확인
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('ae', 'json', 'wsop_plus', 'manual')
ORDER BY schema_name;

-- 예상 결과:
-- ae
-- json
-- manual
-- wsop_plus
```

### 3.2 테이블 카운트 확인

```sql
-- 스키마별 테이블 수
SELECT
    table_schema,
    COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema IN ('ae', 'json', 'wsop_plus', 'manual')
GROUP BY table_schema
ORDER BY table_schema;

-- 예상 결과:
-- ae: 7
-- json: 6
-- manual: 7
-- wsop_plus: 5
```

### 3.3 테이블 상세 확인

```sql
-- 전체 테이블 목록
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('ae', 'json', 'wsop_plus', 'manual')
ORDER BY table_schema, table_name;
```

### 3.4 인덱스 확인

```sql
-- 인덱스 목록
SELECT
    schemaname,
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname IN ('ae', 'json', 'wsop_plus', 'manual')
ORDER BY schemaname, tablename, indexname;
```

### 3.5 RLS 활성화 확인

```sql
-- RLS 상태 확인
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname IN ('ae', 'json', 'wsop_plus', 'manual')
ORDER BY schemaname, tablename;

-- 모든 rowsecurity가 TRUE여야 함
```

### 3.6 트리거 확인

```sql
-- 트리거 목록
SELECT
    event_object_schema,
    event_object_table,
    trigger_name
FROM information_schema.triggers
WHERE event_object_schema IN ('ae', 'json', 'wsop_plus', 'manual')
ORDER BY event_object_schema, event_object_table;
```

### 3.7 함수 확인

```sql
-- 함수 목록
SELECT
    n.nspname AS schema,
    p.proname AS function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname IN ('ae', 'json', 'wsop_plus', 'manual', 'public')
  AND p.proname LIKE '%update%' OR p.proname LIKE '%convert%' OR p.proname LIKE '%format%'
ORDER BY n.nspname, p.proname;
```

---

## 4. API 연동 가이드

### 4.1 Supabase Client 설정

```typescript
// supabase.ts
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseKey, {
  db: {
    schema: 'public'  // 기본 스키마
  }
})

// 스키마별 클라이언트
export const aeClient = createClient(supabaseUrl, supabaseKey, {
  db: { schema: 'ae' }
})

export const jsonClient = createClient(supabaseUrl, supabaseKey, {
  db: { schema: 'json' }
})

export const wsopPlusClient = createClient(supabaseUrl, supabaseKey, {
  db: { schema: 'wsop_plus' }
})

export const manualClient = createClient(supabaseUrl, supabaseKey, {
  db: { schema: 'manual' }
})
```

### 4.2 기본 CRUD 예시

```typescript
// players_master 조회
const { data: players, error } = await manualClient
  .from('players_master')
  .select('*')
  .eq('is_active', true)
  .order('wsop_bracelets', { ascending: false })

// 토너먼트 조회 + 블라인드 레벨
const { data: tournament } = await wsopPlusClient
  .from('tournaments')
  .select(`
    *,
    blind_levels!inner(*)
  `)
  .eq('status', 'running')
  .eq('blind_levels.is_current', true)
  .single()

// GFX 세션 + 핸드 조회
const { data: session } = await jsonClient
  .from('gfx_sessions')
  .select(`
    *,
    hands(
      *,
      hand_players(*),
      hand_results(*)
    )
  `)
  .eq('gfx_id', 638961999170907267)
  .single()
```

### 4.3 Cross-Schema 조회 (Raw SQL)

```typescript
// 크로스 스키마 뷰 사용
const { data } = await supabase
  .rpc('get_feature_table_leaderboard', {
    p_feature_table_id: 'uuid-here'
  })

// 또는 직접 SQL 실행
const { data } = await supabase
  .from('v_feature_table_leaderboard')
  .select('*')
  .eq('feature_table_id', 'uuid-here')
```

### 4.4 Realtime 구독

```typescript
// 핸드 업데이트 구독
const channel = supabase
  .channel('hand-updates')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'json',
      table: 'hands'
    },
    (payload) => {
      console.log('New hand:', payload.new)
    }
  )
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'wsop_plus',
      table: 'player_instances',
      filter: 'is_eliminated=eq.false'
    },
    (payload) => {
      console.log('Chip update:', payload.new)
    }
  )
  .subscribe()
```

---

## 5. 데이터 임포트 가이드

### 5.1 pokerGFX JSON 임포트

```python
# import_pokergfx.py
import json
from supabase import create_client

def import_gfx_session(file_path: str):
    with open(file_path) as f:
        data = json.load(f)

    # 1. 세션 생성
    session = supabase.table('gfx_sessions').insert({
        'gfx_id': data['ID'],
        'event_title': data['EventTitle'],
        'table_type': data['Type'],
        'software_version': data['SoftwareVersion'],
        'created_at_gfx': data['CreatedDateTimeUTC'],
        'payouts': data.get('Payouts', [])
    }).execute()

    session_id = session.data[0]['id']

    # 2. 핸드 임포트
    for hand in data['Hands']:
        import_hand(session_id, hand)

def import_hand(session_id: str, hand_data: dict):
    # 핸드 생성
    hand = supabase.table('hands').insert({
        'gfx_session_id': session_id,
        'hand_number': hand_data['HandNum'],
        'game_variant': hand_data['GameVariant'],
        'bet_structure': hand_data['BetStructure'],
        # ... 기타 필드
    }).execute()

    hand_id = hand.data[0]['id']

    # 플레이어 임포트
    for player in hand_data['Players']:
        supabase.table('hand_players').insert({
            'hand_id': hand_id,
            'seat_number': player['PlayerNum'],
            'player_name': player['Name'],
            'start_stack': player['StartStackAmt'],
            'end_stack': player['EndStackAmt'],
            'hole_cards': player.get('HoleCards'),
            # ... 기타 필드
        }).execute()

    # 액션, 카드, 결과 임포트...
```

### 5.2 WSOP+ CSV 임포트

```python
# import_wsop_csv.py
import pandas as pd

def import_tournament_csv(file_path: str, tournament_id: str):
    df = pd.read_csv(file_path)

    for _, row in df.iterrows():
        # 플레이어 마스터 찾기 또는 생성
        player = find_or_create_player(row['Name'], row.get('Nationality'))

        # 플레이어 인스턴스 업서트
        supabase.table('player_instances').upsert({
            'tournament_id': tournament_id,
            'player_name': row['Name'],
            'chips': row['Chips'],
            'current_rank': row['Rank'],
            'player_master_id': player['id']
        }, on_conflict='tournament_id,player_name').execute()
```

---

## 6. config.toml 설정

### 6.1 API 스키마 노출

```toml
# supabase/config.toml

[api]
# 4개 스키마를 API로 노출
schemas = ["public", "ae", "json", "wsop_plus", "manual"]
extra_search_path = ["public", "extensions"]
max_rows = 1000
```

### 6.2 Realtime 설정

```toml
[realtime]
enabled = true
# IP 허용 (개발용)
ip_range = "0.0.0.0/0"

# 변경 감지할 테이블
[[realtime.subscriptions]]
schema = "json"
tables = ["gfx_sessions", "hands", "hand_players"]

[[realtime.subscriptions]]
schema = "wsop_plus"
tables = ["tournaments", "player_instances", "blind_levels"]
```

---

## 7. 트러블슈팅

### 7.1 스키마 접근 오류

```
오류: permission denied for schema ae

해결:
GRANT USAGE ON SCHEMA ae TO anon, authenticated, service_role;
```

### 7.2 RLS 정책 차단

```
오류: new row violates row-level security policy

해결:
1. 정책 확인: SELECT * FROM pg_policies WHERE schemaname = 'ae';
2. 정책 추가: CREATE POLICY ... ON ae.table_name ...
3. 또는 service_role 키 사용
```

### 7.3 Cross-Schema 조인 오류

```
오류: relation "json.hands" does not exist

해결:
1. 스키마 검색 경로 확인: SHOW search_path;
2. 설정: SET search_path TO public, ae, json, wsop_plus, manual;
3. 또는 풀 네임 사용: json.hands
```

### 7.4 Soft FK 정합성 오류

```
문제: tournament_id가 참조하는 레코드가 없음

해결:
1. 데이터 정합성 검사 스크립트 실행
2. 고아 레코드 NULL 처리 또는 삭제
3. 임포트 시 참조 대상 먼저 생성
```

---

## 8. 성능 최적화

### 8.1 권장 인덱스

이미 migration에 포함되어 있지만, 추가로 필요한 경우:

```sql
-- 자주 사용되는 조인 컬럼
CREATE INDEX CONCURRENTLY idx_json_hp_player_name_lower
ON json.hand_players (LOWER(player_name));

-- GIN 인덱스 (JSONB 검색용)
CREATE INDEX CONCURRENTLY idx_manual_players_alternate_names
ON manual.players_master USING gin (alternate_names);
```

### 8.2 Materialized View

자주 사용되는 크로스 스키마 조회:

```sql
CREATE MATERIALIZED VIEW public.mv_feature_table_leaderboard AS
SELECT ... -- v_feature_table_leaderboard와 동일
WITH DATA;

-- 주기적 새로고침
REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_feature_table_leaderboard;
```

---

## 9. 체크리스트

### 9.1 배포 전 체크리스트

- [ ] 모든 migration 파일 생성 완료
- [ ] 로컬 환경에서 `supabase db reset` 성공
- [ ] 스키마 4개 생성 확인
- [ ] 테이블 25개 생성 확인
- [ ] 인덱스 생성 확인
- [ ] RLS 활성화 확인
- [ ] 트리거 동작 확인 (`updated_at` 자동 갱신)
- [ ] config.toml API schemas 설정

### 9.2 통합 테스트 체크리스트

- [ ] 플레이어 마스터 CRUD
- [ ] 토너먼트 + 블라인드 레벨 조회
- [ ] GFX 세션 + 핸드 임포트
- [ ] Cross-Schema 뷰 조회
- [ ] Realtime 구독 동작

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [PRD-0004](../0004-prd-caption-database-schema.md) | 기존 wsop 단일 스키마 |
| [PRD-0006](../0006-prd-aep-data-elements.md) | AEP 데이터 요소 명세 |
| [Supabase Docs](https://supabase.com/docs) | Supabase 공식 문서 |
