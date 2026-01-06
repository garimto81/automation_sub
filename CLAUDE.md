# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **상위 프로젝트**: `C:\claude\CLAUDE.md` 규칙 상속 (기본 규칙, 시각화, Checklist 등)

---

## Project Overview

**WSOP Broadcast Graphics - 서브 프로젝트** (`automation_sub`)

WSOP 포커 토너먼트 방송 그래픽 시스템의 PRD 문서 관리 및 자동화 스크립트 저장소.

---

## 스크립트 명령

### 다이어그램 캡처 (Playwright 필수)

```powershell
# HTML 목업 → PNG 캡처 (#capture-target 요소)
python scripts/capture_prd_diagrams.py
```

### Google API 스크립트 (OAuth 인증 필요)

```powershell
# PRD → Google Docs 변환 (스타일 자동 적용)
python scripts/create_prd_google_docs.py

# Google Docs에 이미지 삽입
python scripts/add_images_to_prd.py

# Google Slides 이미지 추출 (100KB+ 이미지만)
python scripts/extract_slide_images.py
```

### 슬라이드 분석

```powershell
# 슬라이드 이미지 분석
python scripts/analyze_slide_images.py

# 자막 이미지 추출 (슬라이드 20-62)
python scripts/extract_captions_20_62.py
```

---

## 의존성 설치

```powershell
pip install -r requirements.txt
npx playwright install chromium  # 캡처 스크립트용
```

### OAuth 인증 (Google API)

Google API 스크립트는 `D:\AI\claude01\json\` 경로의 credentials 사용:
- `desktop_credentials.json` - OAuth 클라이언트 ID
- `token.json` - 캐시된 액세스 토큰 (자동 생성)

---

## PRD 아키텍처

### 3개 PRD 의존성

```
PRD-0001 (Graphics)      # 26개 자막 유형, UI 컴포넌트, 디자인 가이드
    ↓
PRD-0002 (Automation)    # 5대 자동화 영역, AI Agent 아키텍처
    ↓
PRD-0003 (Caption)       # 데이터 수집→DB→자막 파이프라인
```

### PRD 수정 규칙

| 규칙 | 설명 |
|------|------|
| **Changelog 필수** | 버전, 날짜, 변경 내용 기록 |
| **이미지 경로** | `../../docs/images/` (상대 경로) |
| **Source Documents** | Google Slides 링크 유지 |

### 핵심 기술 스택

| Layer | Technology |
|-------|------------|
| Frontend | React + TypeScript, Framer Motion |
| Backend | FastAPI, WebSocket |
| Database | PostgreSQL (10개 테이블) |
| AI | OpenAI GPT-4o |

### 데이터 소스 (PRD-0003, 상호 배타적)

| 소스 | 범위 |
|------|------|
| pokerGFX JSON | Feature Table 전용 (RFID) |
| WSOP+ CSV | 대회 정보 + Other Tables |
| 수기 입력 | 프로필, 좌석, 코멘테이터 |

---

## 프로젝트 구조

```
automation_sub/
├── tasks/prds/           # PRD 문서 (핵심)
│   ├── 0001-prd-wsop-broadcast-graphics.md
│   ├── 0002-prd-workflow-automation.md
│   └── 0003-prd-caption-workflow.md
├── scripts/              # Python 자동화 스크립트 (7개)
├── docs/
│   ├── images/
│   │   ├── captions/     # 자막 디자인 참조 (100+개)
│   │   └── slides/       # Slides 추출 이미지
│   ├── mockups/          # HTML 목업 파일
│   └── checklists/       # PRD별 체크리스트
└── .claude/
```
