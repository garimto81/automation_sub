# Part 3: Caption Fields (자막별 데이터 필드 명세)

이 문서는 AEP 분석 결과를 기반으로 각 자막 콤포지션별 동적 레이어와 필요 데이터 필드를 정의합니다.

---

## 3.1 Feature Table Leaderboard

### 콤포지션 정보

| 항목 | MAIN | SUB |
|------|------|-----|
| **콤포지션명** | Feature Table Leaderboard MAIN | Feature Table Leaderboard SUB |
| **해상도** | 1920x1080 | 1920x1080 |
| **레이어 수** | 80개 | 80개 |
| **텍스트 레이어** | 42개 | 41개 |
| **이미지 레이어** | 8개 (Flag) | 9개 (Flag) |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 타입 | 예시 | 데이터 소스 |
|----------|------|------|------|------------|
| Name 1 ~ 8 | player_name | VARCHAR | "DANIEL REZAEI" | DB |
| Chips 1 ~ 8 | chips | VARCHAR | "22,975,000" | CSV/GFX |
| BBs 1 ~ 8 | bb_count | VARCHAR | "114" | 계산 (chips / big_blind) |
| Date 1 ~ 8 | rank | VARCHAR | "1" ~ "8" | DB |
| leaderboard final table | title | VARCHAR | "leaderboard final table" | 고정/수기 |
| WSOP SUPER CIRCUIT CYPRUS | event_name | VARCHAR | "WSOP SUPER CIRCUIT CYPRUS" | DB (events) |

### 이미지 레이어 (동적)

| 레이어명 | 필드 | 설명 | 경로 패턴 |
|----------|------|------|----------|
| Flag 1 ~ 9 | nationality | 국기 이미지 | `Flag/{nationality}.png` |

### 필요 데이터 (8명)

```typescript
interface FeatureTableLeaderboardData {
  event_name: string;           // "WSOP SUPER CIRCUIT CYPRUS"
  table_title: string;          // "leaderboard final table" 또는 "leaderboard table 2"
  players: {
    rank: number;               // 1-8
    name: string;               // "DANIEL REZAEI"
    nationality: string;        // "AT" (ISO 2 code)
    chips: number;              // 22975000
    bb_count: number;           // 114
  }[];
}
```

---

## 3.2 Mini Chip Counts

### 콤포지션 정보

| 항목 | MAIN | SUB |
|------|------|-----|
| **콤포지션명** | _MAIN Mini Chip Count | _SUB_Mini Chip Count |
| **해상도** | 1920x1080 | 1920x1080 |
| **텍스트 레이어** | 21개 | 21개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| name 1 ~ 8 / Name 1 ~ 7 | player_name | "Lipauka" | DB |
| Chip 1 ~ 8 / Chips 1 ~ 7 | chips_with_bb | "2,225,000 (56BB)" | CSV/GFX |
| AVERAGE STACK : ... | avg_stack | "AVERAGE STACK : 6,860,000 (45BB)" | 계산 |

### 필요 데이터

```typescript
interface MiniChipCountData {
  avg_stack: number;            // 6860000
  avg_bb: number;               // 45
  players: {
    name: string;               // "Lipauka"
    chips: number;              // 2225000
    bb_count: number;           // 56
  }[];  // 최대 8명 (MAIN) 또는 7명 (SUB)
}
```

---

## 3.3 Payouts

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Payouts |
| **해상도** | 1920x1080 |
| **텍스트 레이어** | 31개 |
| **이미지 레이어** | 9개 (Flag) |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| Rank 1 ~ 9 | place | "1" ~ "9" | CSV (payouts) |
| prize 1 ~ 9 | amount | "$1,000,000" | CSV (payouts) |
| Total Prize ... | total_prize | "Total Prize $6,860,000" | CSV (tournaments) |
| WSOP SUPER CIRCUIT CYPRUS | event_name | - | DB (events) |

### 필요 데이터

```typescript
interface PayoutsData {
  event_name: string;
  total_prize: number;          // 6860000
  payouts: {
    place: number;              // 1-9
    amount: number;             // 1000000
    nationality?: string;       // 우승자 국적 (확정 시)
  }[];
}
```

---

## 3.4 Mini Payout

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | _Mini Payout |
| **텍스트 레이어** | 29개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 |
|----------|------|------|
| Rank 1 ~ 9 | place | "1" ~ "9" |
| prize 1 ~ 9 | amount | "$1,000,000" |
| Name 9 | last_eliminated | "Georgios Tsouloftas" |
| Total Prize ... | total_prize | "Total Prize $6,860,000" |

---

## 3.5 Event Info

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Event info |
| **텍스트 레이어** | 10개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| WSOP SUPER CIRCUIT CYPRUS | event_name | - | DB (events) |
| Buy-in Fee | buy_in | "$5,300" | CSV (tournaments) |
| Total Fee | prize_pool | "$6,860,000" | CSV (tournaments) |
| Num | entries | "1,372" | CSV (tournaments) |
| % | places_paid | "206TH" | CSV (tournaments) |

### 필요 데이터

```typescript
interface EventInfoData {
  event_name: string;           // "WSOP SUPER CIRCUIT CYPRUS"
  buy_in: number;               // 5300
  prize_pool: number;           // 6860000
  entries: number;              // 1372
  places_paid: number;          // 206
}
```

---

## 3.6 Broadcast Schedule

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Broadcast Schedule |
| **텍스트 레이어** | 23개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| Date 1 ~ 6 | date | "Oct 16" | 수기 (schedules) |
| Event Name 1 ~ 6 | event_title | "MAIN EVENT DAY 1A" | 수기 (schedules) |
| Time 1 ~ 6 | time | "05:10 PM UTC+3" | 수기 (schedules) |
| WSOP SUPER CIRCUIT CYPRUS | series_name | - | DB (events) |

### 필요 데이터 (6개 일정)

```typescript
interface BroadcastScheduleData {
  series_name: string;
  schedules: {
    date: string;               // "Oct 16"
    event_title: string;        // "MAIN EVENT DAY 1A"
    time: string;               // "05:10 PM UTC+3"
  }[];  // 최대 6개
}
```

---

## 3.7 Commentator

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Commentator |
| **텍스트 레이어** | 8개 |
| **이미지 레이어** | 2개 (프로필 사진) |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| Name 1 | commentator_name_1 | "Aaron Paul Kramer" | 수기 (commentators) |
| Name 2 | commentator_name_2 | "Bobby James" | 수기 (commentators) |
| Sub 3 | social_handle_1 | "@aaronpaulkramer" | 수기 (commentators) |
| Sub 4 | social_handle_2 | "@bobbyjamespoker" | 수기 (commentators) |

### 이미지 레이어 (동적)

| 레이어명 | 필드 | 설명 |
|----------|------|------|
| (PSD 파일) | photo_1 | 해설자 1 프로필 사진 |
| (PSD 파일) | photo_2 | 해설자 2 프로필 사진 |

### 필요 데이터

```typescript
interface CommentatorData {
  commentators: {
    name: string;               // "Aaron Paul Kramer"
    social_handle: string;      // "@aaronpaulkramer"
    photo_url: string;          // 프로필 사진 URL
  }[];  // 2명
}
```

---

## 3.8 Location (Venue)

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Location |
| **텍스트 레이어** | 2개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| 2025 wsop super circuit cyprus | series_year_name | "2025 wsop super circuit cyprus" | 수기 (events) |
| merit royal diamond hotel | venue_name | "merit royal diamond hotel" | 수기 (venues) |

---

## 3.9 Chip Flow

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Chip Flow |
| **텍스트 레이어** | 15개 |
| **이미지 레이어** | 1개 (Flag) |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| Player Name | player_name | "REZAEI" | DB |
| max_label | chip_max | "225,000" | GFX (chip_flow) |
| min_label | chip_min | "-1,000" | GFX (chip_flow) |
| input 5_display | current_chips | "224,800" | GFX |
| 하단 라스트 몇 핸드 | hands_label | "LAST 10 HANDS" | 고정/수기 |

> **참고**: Chip Flow 데이터는 주로 GFX에서 실시간 수신 (본 문서 범위 외)

---

## 3.10 Chip Comparison

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Chip Comparison |
| **텍스트 레이어** | 4개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 |
|----------|------|------|
| 플레이어 네임, BB 입력 | player_name_bb | "● alex foxen(67BB)" |
| Others | others_label | "● others" |
| Player % | percentage_label | "payments" |

---

## 3.11 VPIP Stats (Chip VPIP)

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Chip VPIP |
| **텍스트 레이어** | 3개 |
| **이미지 레이어** | 1개 (Flag) |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| Player Name | player_name | "DANIEL REZAEI" | DB |
| % auto | vpip_percentage | 그래프 | GFX (player_stats) |

> **참고**: VPIP 데이터는 GFX에서 실시간 계산 (본 문서 범위 외)

---

## 3.12 Chips In Play

### 콤포지션 정보

| 항목 | x3 | x4 |
|------|-----|-----|
| **콤포지션명** | Chips In Play x3 | Chips In Play x4 |
| **텍스트 레이어** | 4개 | 5개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| Fee 1 ~ 4 | chip_values | "5,000", "25,000", "100,000" | DB/계산 |

---

## 3.13 Elimination Banner

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Elimination |
| **텍스트 레이어** | 2개 |
| **이미지 레이어** | 1개 (Flag) |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| Text 제목 2 | player_name | "Mehmet Dalkilic" | DB/GFX |
| Text 내용 2 | elimination_info | "ELIMINATED IN 10TH PLACE ($64,600)" | GFX (eliminations) |

### 필요 데이터

```typescript
interface EliminationData {
  player_name: string;          // "Mehmet Dalkilic"
  nationality: string;          // "TR"
  final_rank: number;           // 10
  payout: number;               // 64600
}
```

---

## 3.14 At Risk of Elimination

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | At Risk of Elimination |
| **텍스트 레이어** | 1개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| Text 내용 | at_risk_info | "AT RISK OF ELIMINATION - 39TH ($27,700)" | CSV/계산 |

### 필요 데이터

```typescript
interface AtRiskData {
  bubble_rank: number;          // 39
  bubble_payout: number;        // 27700
}
```

---

## 3.15 Player Profile (NAME)

### 콤포지션 정보

| 변형 | 설명 | 텍스트 레이어 |
|------|------|-------------|
| NAME | 2줄 (이름 + 스택) | 2개 |
| NAME 1줄 | 이름만 | 2개 |
| NAME 2줄 (국기 빼고) | 국기 없음 | 2개 |
| NAME 3줄+ | 이름 + 현재/이전 스택 | 2개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 |
|----------|------|------|
| NAME | player_name | "Andrei Spataru" |
| Text 내용 | stack_info | "CURRENT STACK - 3,025,000 (20BB)" |
| Text 내용 2줄 | stack_multi | "CURRENT STACK - 60,500 (24BB)\rPREVIOUS STACK - 21,..." |

### 이미지 레이어

| 레이어명 | 필드 | 설명 |
|----------|------|------|
| (Flag) | nationality | 국기 이미지 |

---

## 3.16 Block Transition Level-Blinds

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Block Transition Level-Blinds |
| **텍스트 레이어** | 12개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| level-1, level-2, level-3 | level_number | "31", "32", "33" | CSV (blind_levels) |
| 75K / 150k ... | blinds_1 | "75K / 150k - 150k (bb)" | CSV (blind_levels) |
| 100K / 200K ... | blinds_2 | "100K / 200K - 200K (bb)" | CSV (blind_levels) |
| 125k / 250k ... | blinds_3 | "125k / 250k - 250k (bb)" | CSV (blind_levels) |
| 60, 61, 62 | duration | "60" (분) | CSV (blind_levels) |

### 필요 데이터 (3개 레벨)

```typescript
interface BlindLevelData {
  levels: {
    level_number: number;       // 31, 32, 33
    small_blind: number;        // 75000, 100000, 125000
    big_blind: number;          // 150000, 200000, 250000
    ante: number;               // 150000, 200000, 250000
    duration: number;           // 60 (분)
  }[];
}
```

---

## 3.17 Event Name

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Event name |
| **텍스트 레이어** | 2개 |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 | 데이터 소스 |
|----------|------|------|------------|
| main event final day | event_title | "main event final day" | 수기 (events) |
| wsop super circuit cyprus | series_name | "wsop super circuit cyprus" | 수기 (events) |

---

## 3.18 Reporter

### 콤포지션 정보

| 항목 | 값 |
|------|-----|
| **콤포지션명** | Reporter |
| **텍스트 레이어** | 3개 |
| **이미지 레이어** | 1개 (프로필 사진) |

### 텍스트 레이어 (동적)

| 레이어명 | 필드 | 예시 |
|----------|------|------|
| Name 1 | reporter_name | "Sample Image" |
| Sub 1 | social_handle | "@sampleimage" |
| Text 제목 4 | title | "Reporter" |

---

## 3.19 데이터 필드 요약

### WSOP+ CSV 필요 필드

| 테이블 | 필드 | 사용 자막 |
|--------|------|----------|
| tournaments | buy_in, prize_pool, entries, places_paid | Event Info |
| blind_levels | level_number, small_blind, big_blind, ante, duration | Block Transition |
| payouts | place, amount | Payouts, Mini Payout, At Risk |

### 수기 입력 필요 필드

| 테이블 | 필드 | 사용 자막 |
|--------|------|----------|
| events | name, series_name | Event Info, Event Name, 모든 자막 헤더 |
| venues | name | Location |
| schedules | date, time, event_title | Broadcast Schedule |
| commentators | name, social_handle, photo_url | Commentator |
| players_master | name, nationality, photo_url | Player Profile, Leaderboard |
