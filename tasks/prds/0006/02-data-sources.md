# Part 2: Data Sources

## 2.1 데이터 소스 분류

### 상호 배타적 원칙

각 데이터 필드는 **하나의 소스에서만** 입력됩니다. 충돌 방지를 위해 소스별 담당 영역이 명확히 구분됩니다.

```
┌─────────────────────────────────────────────────────────────┐
│                    데이터 소스 구조                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐       │
│  │ pokerGFX    │   │ WSOP+ CSV   │   │ 수기 입력    │       │
│  │ JSON        │   │             │   │             │       │
│  ├─────────────┤   ├─────────────┤   ├─────────────┤       │
│  │ Feature     │   │ 대회 정보    │   │ 프로필      │       │
│  │ Table RFID  │   │ 블라인드     │   │ 해설자      │       │
│  │ 실시간 데이터 │   │ 상금 구조    │   │ 일정        │       │
│  │ (제외)      │   │ Other Table │   │ Feature     │       │
│  │             │   │ 플레이어 칩  │   │ Table 구성  │       │
│  └─────────────┘   └─────────────┘   └─────────────┘       │
│       ❌              ✅               ✅                   │
│    PRD-0004        본 문서 범위       본 문서 범위          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2.2 WSOP+ CSV 데이터

### 담당: Data Manager

WSOP+ 시스템에서 내보내는 대회 운영 데이터입니다.

### 테이블별 필드

#### tournaments (대회 정보)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| name | VARCHAR | 대회명 | "MAIN EVENT" |
| buy_in | INTEGER | 바이인 금액 | 5300 |
| prize_pool | BIGINT | 총 상금 | 6860000 |
| registered_players | INTEGER | 총 참가자 | 1372 |
| remaining_players | INTEGER | 남은 참가자 | 8 |
| places_paid | INTEGER | 상금 지급 순위 | 206 |

#### blind_levels (블라인드 레벨)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| level_number | INTEGER | 레벨 번호 | 32 |
| small_blind | INTEGER | 스몰 블라인드 | 100000 |
| big_blind | INTEGER | 빅 블라인드 | 200000 |
| ante | INTEGER | 앤티 | 200000 |
| duration | INTEGER | 레벨 시간 (분) | 60 |

#### payouts (상금 구조)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| place_start | INTEGER | 순위 시작 | 1 |
| place_end | INTEGER | 순위 끝 | 1 |
| amount | BIGINT | 상금 | 1000000 |
| percentage | DECIMAL | 비율 (%) | 14.6 |

#### player_instances (Other Tables 칩)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| chips | BIGINT | 현재 칩 | 22975000 |
| current_rank | INTEGER | 현재 순위 | 1 |

> **주의**: Feature Table 플레이어의 칩은 pokerGFX JSON에서 실시간 수신

---

## 2.3 수기 입력 데이터

### 담당별 필드

#### PA (Production Assistant) - 현장

| 테이블 | 필드 | 설명 |
|--------|------|------|
| player_instances | seat_number | 좌석 번호 (1-9) |
| feature_tables | players[] | 테이블 플레이어 배치 |

#### PD (Program Director) - 디렉터

| 테이블 | 필드 | 설명 |
|--------|------|------|
| player_instances | is_feature_table | Feature Table 여부 |
| events | name, type | 이벤트 정보 |
| venues | name, location | 장소 정보 |

#### Data Manager

| 테이블 | 필드 | 설명 |
|--------|------|------|
| players_master | long_name | 풀네임 |
| players_master | photo_url | 프로필 사진 URL |
| players_master | nationality | 국적 코드 (ISO 2) |
| players_master | bracelets | 브레이슬릿 수 |

#### Production Team

| 테이블 | 필드 | 설명 |
|--------|------|------|
| commentators | name | 해설자 이름 |
| commentators | credentials | 직함/소속 |
| commentators | social_handle | SNS 핸들 |
| commentators | photo_url | 프로필 사진 |
| schedules | date | 방송 날짜 |
| schedules | time_start | 시작 시간 |
| schedules | title | 방송 제목 |

---

## 2.4 자막별 데이터 소스 매핑

| 자막 유형 | WSOP+ CSV | 수기 입력 | GFX JSON (제외) |
|----------|:---------:|:---------:|:---------------:|
| Feature Table LB | - | seat, is_feature | chips, rank |
| Mini Chip Counts | - | - | chips, rank |
| Payouts | payouts | - | - |
| Mini Payouts | payouts | - | - |
| Event Info | tournaments | events | - |
| Broadcast Schedule | - | schedules | - |
| Commentator Profile | - | commentators | - |
| Venue/Location | - | venues | - |
| Chip Flow | - | - | chip_flow |
| Chip Comparison | - | - | chips |
| VPIP Stats | - | - | player_stats |
| Chips In Play | blind_levels | - | chips |
| Elimination Banner | - | - | eliminations |
| At Risk | payouts | - | chips |
| Player Profile | - | players_master | - |
| Blind Level | blind_levels | - | - |
| Event Name | - | events | - |

---

## 2.5 데이터 흐름

```
┌─────────────────────────────────────────────────────────────┐
│                      데이터 입력 흐름                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   WSOP+ 시스템                                              │
│   ┌─────────────┐                                          │
│   │  CSV Export │ ─────────┐                               │
│   └─────────────┘          │                               │
│                            ▼                               │
│   운영자 입력           ┌─────────────┐                     │
│   ┌─────────────┐      │   wsop DB   │                     │
│   │  Web UI     │ ────▶│   스키마    │                     │
│   └─────────────┘      └─────────────┘                     │
│                            │                               │
│                            ▼                               │
│                    ┌─────────────┐                         │
│                    │   API       │                         │
│                    └─────────────┘                         │
│                            │                               │
│                            ▼                               │
│                    ┌─────────────┐                         │
│                    │  AE 렌더링  │                         │
│                    │  (Nexrender)│                         │
│                    └─────────────┘                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2.6 데이터 갱신 주기

| 데이터 소스 | 갱신 주기 | 방식 |
|------------|----------|------|
| WSOP+ CSV | 레벨 종료 시 | 수동 업로드 |
| 수기 입력 (대회 정보) | 대회 시작 전 | 수동 입력 |
| 수기 입력 (좌석 배치) | 테이블 변경 시 | 수동 입력 |
| 수기 입력 (해설자) | 방송 시작 전 | 수동 입력 |

> **참고**: pokerGFX JSON은 실시간 (~1초 간격) 자동 갱신 - 본 문서 범위 외
