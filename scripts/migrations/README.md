# Database Migrations

WSOP Broadcast Graphics Caption System 데이터베이스 마이그레이션 스크립트.

## Migration 파일

| # | 파일 | 설명 | PRD |
|---|------|------|-----|
| 001 | `001_create_caption_tables.sql` | 기본 테이블 13개 생성 | PRD-0003 |
| 002 | `002_extend_gfx_schema.sql` | pokerGFX 확장 테이블 7개 | PRD-0004 |
| 003 | `003_create_views_functions.sql` | View 11개 + 함수 6개 | PRD-0004 |

## 실행 순서

```bash
# PostgreSQL 접속
psql -U postgres -d wsop_graphics

# 순차 실행 (필수)
\i scripts/migrations/001_create_caption_tables.sql
\i scripts/migrations/002_extend_gfx_schema.sql
\i scripts/migrations/003_create_views_functions.sql
```

## 테이블 구조

### 001: Core Tables (13개)

```
venues              # 장소 정보
events              # 이벤트 (WSOP LV, Cyprus)
commentators        # 코멘테이터 정보
schedules           # 방송 스케줄
tournaments         # 토너먼트 정보
blind_levels        # 블라인드 레벨
payouts             # 상금 구조
players             # 플레이어 정보
player_profiles     # 플레이어 프로필 상세
player_stats        # 플레이어 통계 (VPIP, PFR)
chip_history        # 칩 변동 히스토리
graphics_queue      # 그래픽 큐
```

### 002: GFX Tables (7개)

```
feature_tables      # 피처 테이블 관리
gfx_sessions        # pokerGFX 세션 데이터
hands               # 핸드 메타정보 (GFX Hand)
hand_players        # 핸드별 플레이어 상태 (GFX Player)
hand_actions        # 핸드 액션 로그 (GFX Event)
community_cards     # 커뮤니티 카드 (GFX BOARD CARD)
eliminations        # 탈락 상세 정보
soft_contents       # 소프트 콘텐츠 큐
```

### 003: Views & Functions

**Views (11개)**:
- `v_tournament_leaderboard` - 전체 순위표
- `v_feature_table_players` - 피처 테이블 플레이어
- `v_mini_chip_counts` - 미니 칩 카운트
- `v_player_profile` - 플레이어 프로필
- `v_at_risk_players` - 탈락 위기 플레이어
- `v_recent_eliminations` - 최근 탈락자
- `v_chip_flow` - 칩 흐름
- `v_vpip_stats` - VPIP/PFR 통계
- `v_hand_summary` - 핸드 요약
- `v_current_blind_level` - 현재 블라인드 레벨
- `v_l_bar_standard` - L-Bar 표준

**Functions (6개)**:
- `convert_gfx_card(TEXT)` - GFX 카드 형식 변환
- `convert_gfx_hole_cards(JSONB)` - GFX 홀 카드 변환
- `calculate_bb_count(INTEGER, INTEGER)` - BB 계산
- `calculate_avg_stack_percentage(INTEGER, INTEGER)` - 평균 스택 대비 %
- `update_player_ranks(UUID)` - 순위 업데이트
- `import_gfx_session(JSONB, UUID, UUID)` - GFX 세션 임포트

## pokerGFX 카드 형식 변환

| pokerGFX | DB/phevaluator | 설명 |
|----------|----------------|------|
| `as` | `As` | Ace of Spades |
| `kh` | `Kh` | King of Hearts |
| `10d` | `Td` | Ten of Diamonds |
| `jc` | `Jc` | Jack of Clubs |

```sql
-- 사용 예시
SELECT convert_gfx_card('as');  -- 'As'
SELECT convert_gfx_card('10d'); -- 'Td'
SELECT convert_gfx_hole_cards('["as", "kh"]'::JSONB); -- 'AsKh'
```

## Rollback

각 migration 파일 하단에 Rollback 스크립트가 포함되어 있습니다.

```sql
-- 전체 롤백 (역순)
-- 003 롤백
DROP VIEW IF EXISTS v_tournament_leaderboard CASCADE;
-- ... (파일 하단 참조)

-- 002 롤백
DROP TABLE IF EXISTS soft_contents CASCADE;
-- ... (파일 하단 참조)

-- 001 롤백
DROP TABLE IF EXISTS graphics_queue CASCADE;
-- ... (파일 하단 참조)
```

## Related Documents

- [PRD-0003: Caption Workflow](../../tasks/prds/0003-prd-caption-workflow.md)
- [PRD-0004: Caption Database Schema](../../tasks/prds/0004-prd-caption-database-schema.md)
