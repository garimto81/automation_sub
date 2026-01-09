# Part 4: DB Mapping (wsop 스키마 매핑)

이 문서는 AEP 동적 레이어와 wsop 스키마 테이블 간의 매핑을 정의합니다.

---

## 4.1 매핑 원칙

1. **1:1 매핑**: 각 AEP 레이어는 하나의 DB 필드에 매핑
2. **계산 필드**: BB 수 등 계산이 필요한 필드는 뷰 또는 API에서 처리
3. **포맷 변환**: 숫자 → 문자열 변환 (쉼표, 통화 기호)은 렌더링 시 처리

---

## 4.2 테이블별 매핑

### tournaments

| DB 필드 | AEP 레이어 | 자막 유형 | 변환 |
|---------|-----------|----------|------|
| name | event_title | Event Name | 그대로 |
| buy_in | Buy-in Fee | Event Info | `$` + 쉼표 |
| prize_pool | Total Fee, Total Prize | Event Info, Payouts | `$` + 쉼표 |
| registered_players | Num | Event Info | 쉼표 |
| remaining_players | - | (직접 사용 안 함) | - |
| places_paid | % | Event Info | `TH` 접미사 |
| avg_stack | AVERAGE STACK | Mini Chip Count | 쉼표 + `(BB)` |

### blind_levels

| DB 필드 | AEP 레이어 | 자막 유형 | 변환 |
|---------|-----------|----------|------|
| level_number | level-1, level-2, level-3 | Block Transition | 그대로 |
| small_blind | blinds 첫 번째 값 | Block Transition | `K` 단위 |
| big_blind | blinds 두 번째 값 | Block Transition | `K` 단위 |
| ante | blinds 세 번째 값 | Block Transition | `K` 단위 |
| duration | 60, 61, 62 | Block Transition | 그대로 |

**변환 예시**: `small_blind: 100000` → `"100K / 200K - 200K (bb)"`

### payouts

| DB 필드 | AEP 레이어 | 자막 유형 | 변환 |
|---------|-----------|----------|------|
| place_start | Rank 1~9 | Payouts | 그대로 |
| amount | prize 1~9 | Payouts | `$` + 쉼표 |

### players_master

| DB 필드 | AEP 레이어 | 자막 유형 | 변환 |
|---------|-----------|----------|------|
| name | Name 1~8, NAME | Feature Table LB, Player Profile | 대문자화 |
| nationality | Flag 1~9 | Feature Table LB, Payouts | ISO2 → Flag 파일명 |
| photo_url | (PSD 파일) | Commentator | URL → 파일 다운로드 |

### player_instances

| DB 필드 | AEP 레이어 | 자막 유형 | 변환 |
|---------|-----------|----------|------|
| chips | Chips 1~8 | Feature Table LB | 쉼표 |
| current_rank | Date 1~8 | Feature Table LB | 그대로 |
| seat_number | - | (내부 사용) | - |

**BB 계산**: `chips / big_blind` → `BBs 1~8`

### events

| DB 필드 | AEP 레이어 | 자막 유형 | 변환 |
|---------|-----------|----------|------|
| name | WSOP SUPER CIRCUIT CYPRUS | 모든 자막 헤더 | 대문자화 |

### venues

| DB 필드 | AEP 레이어 | 자막 유형 | 변환 |
|---------|-----------|----------|------|
| name | merit royal diamond hotel | Location | 소문자화 |

### schedules

| DB 필드 | AEP 레이어 | 자막 유형 | 변환 |
|---------|-----------|----------|------|
| date | Date 1~6 | Broadcast Schedule | "Oct 16" 형식 |
| time_start | Time 1~6 | Broadcast Schedule | "05:10 PM UTC+3" 형식 |
| title | Event Name 1~6 | Broadcast Schedule | 대문자화 |

### commentators

| DB 필드 | AEP 레이어 | 자막 유형 | 변환 |
|---------|-----------|----------|------|
| name | Name 1, Name 2 | Commentator | 그대로 |
| social_handle | Sub 3, Sub 4 | Commentator | `@` 접두사 |
| photo_url | (PSD 파일) | Commentator | URL → 파일 |

---

## 4.3 뷰 활용

### v_tournament_leaderboard

Feature Table Leaderboard 자막에서 직접 사용 가능:

```sql
SELECT
    current_rank,           -- Date 1~8
    player_name,            -- Name 1~8
    nationality,            -- Flag 1~8
    chips,                  -- Chips 1~8
    bb_count                -- BBs 1~8 (계산됨)
FROM wsop.v_tournament_leaderboard
WHERE tournament_id = ?
ORDER BY current_rank
LIMIT 8;
```

### v_feature_table_players

Feature Table Leaderboard MAIN/SUB 구분:

```sql
SELECT
    table_number,           -- MAIN=1, SUB=2
    seat_number,
    player_name,
    chips,
    bb_count
FROM wsop.v_feature_table_players
WHERE tournament_id = ?
ORDER BY table_number, chips DESC;
```

---

## 4.4 포맷 변환 규칙

### 숫자 포맷

| 타입 | DB 값 | AEP 레이어 값 |
|------|-------|--------------|
| 칩 수 | 22975000 | "22,975,000" |
| 상금 | 1000000 | "$1,000,000" |
| BB | 114.5 | "114" (반올림) |
| 순위 | 1 | "1" |

### 단위 변환

| 범위 | 변환 | 예시 |
|------|------|------|
| < 1,000 | 그대로 | "500" |
| 1,000 ~ 999,999 | K | "100K" |
| >= 1,000,000 | M | "1M" |

### 블라인드 포맷

```
{small_blind} / {big_blind} - {ante} (bb)

예: 100000 / 200000 - 200000
→ "100K / 200K - 200K (bb)"
```

---

## 4.5 국기 이미지 매핑

### ISO 2 코드 → 파일명

| nationality | 파일명 |
|-------------|--------|
| AT | `Austria.png` 또는 `AT.png` |
| US | `USA.png` |
| GB | `Great Britain.png` 또는 `UK.png` |
| KR | `South Korea.png` |
| CN | `China.png` |
| JP | `Japan.png` |
| RU | `Russia.png` |
| DE | `Germany.png` |
| FR | `France.png` |
| ... | ... |

**경로**: `(Footage)/Flag/{nationality}.png`

### 예외 처리

| nationality | 처리 |
|-------------|------|
| NULL | `Unknown.png` 사용 |
| 알 수 없는 코드 | `Unknown.png` 사용 |

---

## 4.6 API 응답 구조

### Feature Table Leaderboard API

```json
{
  "event_name": "WSOP SUPER CIRCUIT CYPRUS",
  "table_title": "leaderboard final table",
  "big_blind": 200000,
  "players": [
    {
      "rank": 1,
      "name": "DANIEL REZAEI",
      "nationality": "AT",
      "chips": 22975000,
      "chips_formatted": "22,975,000",
      "bb_count": 114
    }
  ]
}
```

### Payouts API

```json
{
  "event_name": "WSOP SUPER CIRCUIT CYPRUS",
  "total_prize": 6860000,
  "total_prize_formatted": "$6,860,000",
  "payouts": [
    {
      "place": 1,
      "amount": 1000000,
      "amount_formatted": "$1,000,000"
    }
  ]
}
```

---

## 4.7 PRD-0004 연계

### 참조 테이블

| 테이블 | PRD-0004 위치 | 본 문서 사용 |
|--------|--------------|-------------|
| wsop.tournaments | Part 3 | Event Info, Payouts |
| wsop.blind_levels | Part 3 | Block Transition |
| wsop.payouts | Part 3 | Payouts, Mini Payout |
| wsop.players_master | Part 3 | Feature Table LB, Player Profile |
| wsop.player_instances | Part 3 | Feature Table LB, Mini Chip Count |
| wsop.events | Part 3 | 모든 자막 헤더 |
| wsop.venues | Part 3 | Location |
| wsop.schedules | Part 3 | Broadcast Schedule |
| wsop.commentators | Part 3 | Commentator |

### 뷰 활용

| 뷰 | PRD-0004 위치 | 본 문서 사용 |
|----|--------------|-------------|
| wsop.v_tournament_leaderboard | Part 7 | Feature Table LB |
| wsop.v_feature_table_players | Part 7 | Feature Table LB MAIN/SUB |
| wsop.v_eliminations | Part 7 | Elimination Banner |
