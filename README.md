# WSOP Broadcast Graphics - Automation Sub

WSOP 포커 토너먼트 방송 그래픽 시스템의 **PRD 문서 관리 및 자동화 스크립트** 저장소입니다.

## PRD 문서

| PRD | 버전 | 설명 |
|-----|------|------|
| [PRD-0001](tasks/prds/0001-prd-wsop-broadcast-graphics.md) | v2.5 | WSOP Broadcast Graphics System |
| [PRD-0002](tasks/prds/0002-prd-workflow-automation.md) | v1.1 | Workflow Automation System |
| [PRD-0003](tasks/prds/0003-prd-caption-workflow.md) | v1.3 | Caption Generation Workflow |

## 체크리스트

| PRD | 진행률 | 문서 |
|-----|--------|------|
| PRD-0001 | 0% (0/33) | [Checklist](docs/checklists/PRD-0001.md) |
| PRD-0002 | 0% (0/96) | [Checklist](docs/checklists/PRD-0002.md) |
| PRD-0003 | 0% (0/106) | [Checklist](docs/checklists/PRD-0003.md) |

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
├── tasks/prds/           # PRD 문서 (3개)
├── scripts/              # Python 자동화 스크립트 (7개)
├── docs/
│   ├── images/           # 아키텍처 다이어그램 (14개)
│   ├── mockups/          # HTML 목업 (14개)
│   └── checklists/       # PRD별 체크리스트 (3개)
└── CLAUDE.md             # Claude Code 설정
```

## 관련 저장소

- **Main Repository**: [garimto81/claude](https://github.com/garimto81/claude)
