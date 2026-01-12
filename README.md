# WSOP Broadcast Graphics - Automation Sub

WSOP 포커 토너먼트 방송 그래픽 시스템의 **PRD 문서 관리 및 자동화 스크립트** 저장소입니다.

## PRD 문서

| PRD | 버전 | 설명 |
|-----|------|------|
| [PRD-0001](tasks/prds/0001-prd-wsop-broadcast-graphics.md) | v2.6 | WSOP Broadcast Graphics System |
| [PRD-0002](tasks/prds/0002-prd-workflow-automation.md) | v1.1 | Workflow Automation System |
| [PRD-0003](tasks/prds/0003-prd-caption-workflow.md) | v1.3 | Caption Generation Workflow |
| [PRD-0004](tasks/prds/0004-prd-caption-database-schema.md) | v1.2 | Caption Database Schema |
| [PRD-0005](tasks/prds/0005-prd-trigger-db-visualization.md) | v1.1 | Trigger-DB Causality Visualization |
| [PRD-0006](tasks/prds/0006-prd-aep-data-elements.md) | v1.0 | AEP Data Elements & Integration |
| [PRD-0007](tasks/prds/0007-prd-4schema-database-design.md) | v2.0 | 4-Schema Multi-DB Design |

## 체크리스트

| PRD | 문서 |
|-----|------|
| PRD-0001 | [Checklist](docs/checklists/PRD-0001.md) |
| PRD-0002 | [Checklist](docs/checklists/PRD-0002.md) |
| PRD-0003 | [Checklist](docs/checklists/PRD-0003.md) |
| PRD-0004 | [Checklist](docs/checklists/PRD-0004.md) |
| PRD-0005 | [Checklist](docs/checklists/PRD-0005.md) |

## 스크립트

```powershell
# 다이어그램 캡처 (Playwright 필수)
python scripts/capture_prd_diagrams.py

# Google Docs 변환
python scripts/create_prd_google_docs.py

# 슬라이드 이미지 추출
python scripts/extract_slide_images.py
```

## 의존성

```powershell
pip install -r requirements.txt
npx playwright install chromium
```

## 프로젝트 구조

```
automation_sub/
├── tasks/prds/           # PRD 및 기술 명세서 (11개)
├── scripts/              # Python 자동화 스크립트
│   ├── supabase/         # Supabase 관리 스크립트
│   └── archive/          # 과거 버전 아카이브
├── supabase/
│   └── migrations/       # SQL migration 파일
└── docs/
    ├── images/           # PRD별 이미지 폴더
    ├── mockups/          # HTML 목업
    └── checklists/       # PRD별 체크리스트
```

## 관련 저장소

- **Main Repository**: [garimto81/claude](https://github.com/garimto81/claude)
