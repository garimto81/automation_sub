# PRD-0007 Part 2: Schema Architecture

## 1. 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PostgreSQL Database                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │   ae (7개)      │  │  json (6개)     │  │     wsop_plus (5개)         │  │
│  │                 │  │                 │  │                             │  │
│  │ ├─ templates    │  │ ├─ gfx_sessions │  │ ├─ tournaments              │  │
│  │ ├─ compositions │  │ ├─ hands        │  │ ├─ blind_levels             │  │
│  │ ├─ comp_layers  │  │ ├─ hand_players │  │ ├─ payouts                  │  │
│  │ ├─ layer_map    │  │ ├─ hand_actions │  │ ├─ player_instances         │  │
│  │ ├─ data_types   │  │ ├─ hand_cards   │  │ └─ schedules                │  │
│  │ ├─ render_jobs  │  │ └─ hand_results │  │                             │  │
│  │ └─ render_out   │  │                 │  │                             │  │
│  └────────┬────────┘  └────────┬────────┘  └──────────────┬──────────────┘  │
│           │                    │                          │                 │
│           │         ┌──────────┴──────────┐               │                 │
│           │         │   Soft FK / Views   │               │                 │
│           │         └──────────┬──────────┘               │                 │
│           │                    │                          │                 │
│  ┌────────┴────────────────────┴──────────────────────────┴──────────────┐  │
│  │                        manual (7개)                                   │  │
│  │                                                                       │  │
│  │ ├─ players_master    ├─ commentators     ├─ events                    │  │
│  │ ├─ player_profiles   ├─ venues           ├─ feature_tables            │  │
│  │ └─ seating_assignments                                                │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                        public (Views)                                 │  │
│  │ ├─ v_feature_table_leaderboard                                        │  │
│  │ ├─ v_unified_players                                                  │  │
│  │ └─ v_unified_hands                                                    │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. ae 스키마 (After Effects)

### 2.1 목적

AEP 프로젝트 파일의 메타데이터, 컴포지션, 레이어 정보 및 렌더링 작업 관리

### 2.2 테이블 목록

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|----------|
| **templates** | AEP 프로젝트 파일 | name, file_path, checksum |
| **compositions** | 렌더링 가능한 컴포지션 | template_id, name, width, height, frame_rate |
| **composition_layers** | 동적 레이어 | composition_id, layer_name, layer_type, is_dynamic |
| **layer_data_mappings** | 데이터 바인딩 설정 | layer_id, source_schema, source_table, source_column |
| **data_types** | 데이터 유형 정의 | type_name, category, schema_definition (JSONB) |
| **render_jobs** | Nexrender 작업 큐 | composition_id, data_payload (JSONB), status |
| **render_outputs** | 렌더링 결과물 | render_job_id, file_path, storage_url |

### 2.3 ERD

```
┌─────────────────┐
│   templates     │
├─────────────────┤
│ id (PK)         │
│ name            │
│ file_path       │
│ checksum        │
└────────┬────────┘
         │ 1:N
         ▼
┌─────────────────┐
│  compositions   │
├─────────────────┤
│ id (PK)         │
│ template_id(FK) │
│ name            │
│ comp_type       │
│ width, height   │
└────────┬────────┘
         │ 1:N
         ▼
┌─────────────────┐       ┌─────────────────┐
│composition_layer│       │   data_types    │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ composition_id  │       │ type_name       │
│ layer_name      │       │ category        │
│ layer_type      │       │ schema_def      │
│ is_dynamic      │       └────────┬────────┘
└────────┬────────┘                │
         │ 1:1                     │
         ▼                         │
┌─────────────────┐                │
│layer_data_map   │                │
├─────────────────┤                │
│ id (PK)         │                │
│ layer_id (FK)   │                │
│ source_schema   │                │
│ source_table    │                │
│ data_type_id    │◀───────────────┘
└─────────────────┘
```

### 2.4 주요 특성

- **정적 데이터**: AEP 분석 결과, 자주 변경되지 않음
- **캐시 가능**: 템플릿/컴포지션 정보는 캐시 적합
- **매핑 핵심**: layer_data_mappings가 다른 스키마와 연결 고리

---

## 3. json 스키마 (pokerGFX RFID)

### 3.1 목적

pokerGFX에서 실시간으로 수집되는 핸드 데이터 저장

### 3.2 테이블 목록

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|----------|
| **gfx_sessions** | GFX 세션 (JSON 파일 단위) | gfx_id (BIGINT UNIQUE), event_title, table_type |
| **hands** | 핸드 메타데이터 | gfx_session_id, hand_number, game_variant, pot_size |
| **hand_players** | 핸드별 플레이어 상태 | hand_id, seat_number, start_stack, end_stack, hole_cards |
| **hand_actions** | 액션 로그 | hand_id, action_order, street, action, bet_amount |
| **hand_cards** | 커뮤니티/홀 카드 | hand_id, card_rank, card_suit, card_type |
| **hand_results** | 핸드 결과 | hand_id, seat_number, is_winner, won_amount, rank_value |

### 3.3 ERD

```
┌─────────────────┐
│  gfx_sessions   │
├─────────────────┤
│ id (PK)         │
│ gfx_id (UNIQUE) │──── Windows FileTime
│ event_title     │
│ table_type      │
│ tournament_id   │──── Soft FK → wsop_plus.tournaments
│ feature_table_id│──── Soft FK → manual.feature_tables
└────────┬────────┘
         │ 1:N
         ▼
┌─────────────────┐
│     hands       │
├─────────────────┤
│ id (PK)         │
│ gfx_session_id  │
│ hand_number     │
│ game_variant    │
│ pot_size        │
│ grade           │──── A, B, C, D
│ is_premium      │
└────────┬────────┘
         │ 1:N (3개 자식)
         ├─────────────────────────┐
         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐
│  hand_players   │       │  hand_actions   │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ hand_id (FK)    │       │ hand_id (FK)    │
│ seat_number     │       │ action_order    │
│ player_name     │       │ street          │
│ start_stack     │       │ action          │
│ end_stack       │       │ bet_amount      │
│ hole_cards      │       └─────────────────┘
│ is_winner       │
│ player_master_id│──── Soft FK → manual.players_master
└─────────────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐       ┌─────────────────┐
│   hand_cards    │       │  hand_results   │
├─────────────────┤       ├─────────────────┤
│ hand_id (FK)    │       │ hand_id (FK)    │
│ card_rank       │       │ seat_number     │
│ card_suit       │       │ is_winner       │
│ card_type       │       │ won_amount      │
│ seat_number     │       │ rank_value      │
└─────────────────┘       └─────────────────┘
```

### 3.4 주요 특성

- **실시간 데이터**: ~1초 간격 업데이트
- **이벤트 소싱**: hand_actions로 전체 핸드 재현 가능
- **Feature Table 전용**: Other Tables 데이터는 wsop_plus에서 관리

---

## 4. wsop_plus 스키마 (Tournament Operations)

### 4.1 목적

WSOP+ CSV에서 가져오는 토너먼트 운영 데이터 저장

### 4.2 테이블 목록

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|----------|
| **tournaments** | 토너먼트 정보 | name, buy_in, prize_pool, remaining_players |
| **blind_levels** | 블라인드 구조 | tournament_id, level_number, sb, bb, ante |
| **payouts** | 페이아웃 구조 | tournament_id, place_start, place_end, amount |
| **player_instances** | 토너먼트 참가자 | tournament_id, player_name, chips, current_rank |
| **schedules** | 방송 일정 | date, time_start, event_title, channel |

### 4.3 ERD

```
┌─────────────────┐
│   tournaments   │
├─────────────────┤
│ id (PK)         │
│ name            │
│ buy_in          │
│ prize_pool      │
│ remaining_players│
│ status          │
│ event_id        │──── Soft FK → manual.events
└────────┬────────┘
         │ 1:N (3개 자식)
         ├──────────────────────────────────┐
         │                                  │
         ▼                                  ▼
┌─────────────────┐                ┌─────────────────┐
│  blind_levels   │                │    payouts      │
├─────────────────┤                ├─────────────────┤
│ id (PK)         │                │ id (PK)         │
│ tournament_id   │                │ tournament_id   │
│ level_number    │                │ place_start     │
│ small_blind     │                │ place_end       │
│ big_blind       │                │ amount          │
│ ante            │                │ percentage      │
│ is_current      │                │ is_current_bubble│
└─────────────────┘                └─────────────────┘
         │
         ▼
┌─────────────────┐                ┌─────────────────┐
│player_instances │                │   schedules     │
├─────────────────┤                ├─────────────────┤
│ id (PK)         │                │ id (PK)         │
│ tournament_id   │                │ date            │
│ player_name     │                │ time_start      │
│ chips           │                │ event_title     │
│ current_rank    │                │ tournament_id   │──FK
│ is_eliminated   │                │ event_id        │──Soft FK
│ player_master_id│──Soft FK       └─────────────────┘
│ feature_table_id│──Soft FK
└─────────────────┘
```

### 4.4 주요 특성

- **배치 데이터**: CSV 임포트, 레벨 종료 시 업데이트
- **Other Tables 포함**: Feature Table 외 모든 테이블 칩 카운트
- **플레이어 매칭**: player_master_id로 마스터 데이터 연결

---

## 5. manual 스키마 (수작업 입력)

### 5.1 목적

운영팀이 직접 입력하는 마스터 데이터 저장

### 5.2 테이블 목록

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|----------|
| **players_master** | 플레이어 마스터 | name, nationality, wsop_bracelets, total_earnings |
| **player_profiles** | 플레이어 프로필 상세 | player_id, long_name, birth_date, playing_style |
| **commentators** | 코멘테이터 | name, credentials, social_handle |
| **venues** | 장소 | name, city, country, drone_shot_url |
| **events** | 이벤트/시리즈 | event_code, series_name, start_date, end_date |
| **feature_tables** | Feature Table 관리 | table_number, rfid_device_id, is_active |
| **seating_assignments** | 좌석 배정 | player_id, feature_table_id, seat_number |

### 5.3 ERD

```
┌─────────────────┐       ┌─────────────────┐
│ players_master  │       │    venues       │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ name            │       │ name            │
│ nationality     │       │ city            │
│ photo_url       │       │ country         │
│ wsop_bracelets  │       │ drone_shot_url  │
│ total_earnings  │       └────────┬────────┘
│ is_key_player   │                │ 1:N
└────────┬────────┘                ▼
         │ 1:1            ┌─────────────────┐
         ▼                │     events      │
┌─────────────────┐       ├─────────────────┤
│ player_profiles │       │ id (PK)         │
├─────────────────┤       │ event_code      │
│ id (PK)         │       │ venue_id (FK)   │
│ player_id (FK)  │       │ start_date      │
│ long_name       │       │ end_date        │
│ birth_date      │       │ sponsor_logos   │
│ playing_style   │       └─────────────────┘
└─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│  commentators   │       │ feature_tables  │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ name            │       │ table_number    │
│ credentials     │       │ rfid_device_id  │
│ social_handle   │       │ is_active       │
│ photo_url       │       │ tournament_id   │──Soft FK
└─────────────────┘       └────────┬────────┘
                                   │ 1:N
         ┌─────────────────────────┘
         ▼
┌─────────────────┐
│seating_assign   │
├─────────────────┤
│ id (PK)         │
│ player_id (FK)  │──► players_master
│ feature_table_id│
│ seat_number     │
│ is_current      │
└─────────────────┘
```

### 5.4 주요 특성

- **마스터 데이터**: 토너먼트 무관 영구 데이터
- **중복 제거**: players_master로 플레이어 통합 관리
- **수동 입력**: 자동화 불가능한 데이터 (프로필, 코멘테이터)

---

## 6. 스키마별 설계 원칙

| 원칙 | 적용 |
|------|------|
| **UUID PK** | 모든 테이블 `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` |
| **JSONB 유연성** | 복잡한 구조는 JSONB 컬럼 사용 (payouts, social_links) |
| **TIMESTAMPTZ** | 모든 시간 컬럼은 타임존 포함 |
| **Soft Delete** | is_active, is_eliminated 등 Boolean 플래그 |
| **Auto Timestamp** | created_at, updated_at 자동 갱신 트리거 |
| **Unique Constraint** | 비즈니스 키에 UNIQUE 제약 (gfx_id, event_code) |

---

## 다음 파트

→ [Part 3: Cross-Schema Mapping](03-cross-schema-mapping.md)
