# PRD-0007: 4-Schema Database Design

| 항목 | 내용 |
|------|------|
| **문서 ID** | PRD-0007 |
| **제목** | 4-Schema Database Design (ae, json, wsop_plus, manual) |
| **버전** | 1.0.0 |
| **작성일** | 2026-01-09 |
| **상태** | Draft |
| **Parent PRD** | PRD-0004 (Caption DB), PRD-0006 (AEP Data Elements) |

---

## 목차

| Part | 제목 | 파일 |
|------|------|------|
| 1 | [Overview](0007/01-overview.md) | 목적, 범위, 스키마 분리 전략 |
| 2 | [Schema Architecture](0007/02-schema-architecture.md) | 4개 스키마 구조, 테이블 목록 |
| 3 | [Cross-Schema Mapping](0007/03-cross-schema-mapping.md) | 스키마 간 관계, FK 전략, 뷰 |
| 4 | [Data Flow](0007/04-data-flow.md) | 데이터 소스 → 스키마 → 자막 흐름 |
| 5 | [Implementation Guide](0007/05-implementation-guide.md) | Migration 적용, 검증, API 연동 |

---

## 요약

### 스키마 분리 전략

기존 단일 `wsop` 스키마를 **4개 분리 스키마**로 재설계:

| 스키마 | 데이터 소스 | 업데이트 주기 | 테이블 수 |
|--------|------------|--------------|----------|
| **ae** | After Effects AEP | On-demand | 7개 |
| **json** | pokerGFX RFID | 실시간 (~1초) | 6개 |
| **wsop_plus** | WSOP+ CSV | 배치/이벤트 | 5개 |
| **manual** | 수작업 입력 | 수동 | 7개 |

**총 25개 테이블**, UUID PK, JSONB 지원, RLS 활성화

### 분리 이유

1. **데이터 소스 분리**: 각 소스별 독립적 관리
2. **업데이트 주기 분리**: 실시간 vs 배치 vs 수동
3. **권한 분리**: 스키마별 RLS 정책 적용
4. **확장성**: 새 소스 추가 시 스키마 추가로 대응

### 테이블 개요

```
ae (7개)
├── templates          # AEP 프로젝트 파일
├── compositions       # 렌더링 가능한 컴포지션
├── composition_layers # 동적 레이어
├── layer_data_mappings# 데이터 바인딩
├── data_types         # 데이터 유형 정의
├── render_jobs        # Nexrender 작업
└── render_outputs     # 렌더링 결과물

json (6개)
├── gfx_sessions       # pokerGFX 세션
├── hands              # 핸드 메타데이터
├── hand_players       # 핸드별 플레이어 상태
├── hand_actions       # 액션 로그
├── hand_cards         # 커뮤니티/홀 카드
└── hand_results       # 핸드 결과

wsop_plus (5개)
├── tournaments        # 토너먼트 정보
├── blind_levels       # 블라인드 구조
├── payouts            # 페이아웃 구조
├── player_instances   # 토너먼트 참가자
└── schedules          # 방송 일정

manual (7개)
├── players_master     # 플레이어 마스터
├── player_profiles    # 플레이어 프로필 상세
├── commentators       # 코멘테이터
├── venues             # 장소
├── events             # 이벤트/시리즈
├── feature_tables     # Feature Table 관리
└── seating_assignments# 좌석 배정
```

---

## 관련 문서

| PRD | 제목 | 관계 |
|-----|------|------|
| PRD-0001 | Broadcast Graphics | 26개 자막 유형 정의 |
| PRD-0003 | Caption Workflow | 데이터 수집 워크플로우 |
| PRD-0004 | Caption Database Schema | 기존 wsop 단일 스키마 |
| PRD-0006 | AEP Data Elements | AEP 동적 레이어 명세 |

---

## Migration 파일

```
supabase/migrations/
├── 20260110000000_create_schemas.sql
├── 20260110000100_ae_schema_tables.sql
├── 20260110000200_json_schema_tables.sql
├── 20260110000300_wsop_plus_schema_tables.sql
├── 20260110000400_manual_schema_tables.sql
├── 20260110000500_indexes.sql
├── 20260110000600_functions_triggers.sql
└── 20260110000700_rls_policies.sql
```

---

## Changelog

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-01-09 | 초안 작성 - 4개 스키마 분리 설계 |
