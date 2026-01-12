# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **상위 프로젝트**: `C:\claude\CLAUDE.md` 규칙 상속 (기본 규칙, 시각화, Checklist 등)

---

## Project Overview

**WSOP Broadcast Graphics - 서브 프로젝트** (`automation_sub`)

WSOP 포커 토너먼트 방송 그래픽 시스템의 PRD 문서 관리, Supabase DB 스키마, 자동화 스크립트 저장소.

---

## 스크립트 명령

### 다이어그램 캡처 (Playwright 필수)

```powershell
python scripts/capture_prd_diagrams.py  # HTML 목업 → PNG (#capture-target)
```

### Google API 스크립트 (OAuth 인증 필요)

```powershell
python scripts/create_prd_google_docs.py   # PRD → Google Docs 변환
python scripts/add_images_to_prd.py        # Google Docs에 이미지 삽입
python scripts/extract_slide_images.py    # Slides 이미지 추출 (100KB+)
python scripts/create_caption_sheet.py    # Caption Sheet 생성
```

### 슬라이드 분석

```powershell
python scripts/analyze_slide_images.py    # 슬라이드 이미지 분석
python scripts/extract_captions_20_62.py  # 자막 이미지 추출 (20-62)
```

### Supabase Migration

```powershell
python scripts/supabase/combine_migrations.py   # SQL 파일 병합
python scripts/supabase/apply_migrations.py     # Migration 적용
python scripts/supabase/apply_via_api.py        # REST API로 적용
python scripts/supabase/apply_ipv6.py           # IPv6 네트워크 적용
```

---

## 의존성 설치

```powershell
pip install -r requirements.txt
npx playwright install chromium
```

### OAuth 인증 (Google API)

`D:\AI\claude01\json\` 경로의 credentials 사용:
- `desktop_credentials.json` - OAuth 클라이언트 ID
- `token.json` - 캐시된 액세스 토큰 (자동 생성)

---

## 공유 인프라 (automation_hub)

| 문서 | 위치 |
|------|------|
| Hub PRD | `C:\claude\automation_hub\docs\prds\` |
| Schema 설계 | `C:\claude\automation_hub\docs\SCHEMA_DESIGN.md` |


---

## Supabase 설정

### wsop 스키마 분리

```
public (기본)     → 사용 안 함 (RLS 복잡도)
wsop (전용)       → Caption DB 전용 스키마
```

### Migration 파일

```
supabase/migrations/
├── 20260108103017_remote_schema.sql    # 원격 스키마 동기화
├── 20260108210000_create_schemas.sql   # 스키마 생성
├── 20260108220000_wsop_caption_schema.sql  # Caption 테이블
└── 20260108230000_wsop_functions_views.sql # 함수/뷰
```

### 로컬 개발

```powershell
supabase start       # 로컬 Supabase 시작
supabase db reset    # DB 초기화 + migration 적용
supabase db push     # 원격 DB에 migration 적용
```

---

## 핵심 기술 스택

| Layer | Technology |
|-------|------------|
| Frontend | React + TypeScript, Framer Motion |
| Backend | FastAPI, WebSocket |
| Database | Supabase (PostgreSQL, wsop 스키마) |
| AI | OpenAI GPT-4o |

### 데이터 소스 (PRD-0003, 상호 배타적)

| 소스 | 범위 |
|------|------|
| pokerGFX JSON | Feature Table 전용 (RFID) |
| WSOP+ (Main) | 모든 테이블 (좌석, 칩, 선수 등) |
| 수기 입력 | 프로필, 코멘테이터 보완 |

---

## 프로젝트 구조

```
automation_sub/
├── tasks/prds/           # PRD 문서 (5개 + 분할 폴더)
├── scripts/              # Python 자동화 스크립트 (12개)
│   └── supabase/         # Supabase migration 스크립트
├── supabase/
│   ├── config.toml       # Supabase 설정
│   └── migrations/       # SQL migration 파일
├── docs/
│   ├── images/
│   │   ├── captions/     # 자막 디자인 참조
│   │   └── slides/       # Slides 추출 이미지
│   ├── mockups/          # HTML 목업 파일
│   └── checklists/       # PRD별 체크리스트
└── .claude/
```
