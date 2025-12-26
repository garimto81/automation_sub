# 이미지 참조 가이드

이 폴더에는 PRD 문서에 사용되는 다이어그램 이미지가 포함되어 있습니다.

## 아키텍처 다이어그램

각 PNG 이미지는 `mockups/` 폴더의 HTML 소스에서 생성되었습니다.

| 이미지 | HTML 소스 | 설명 |
|--------|-----------|------|
| [ai-agent-hierarchy.png](ai-agent-hierarchy.png) | [HTML](../mockups/ai-agent-hierarchy.html) | AI 에이전트 계층 구조 |
| [automation-domains.png](automation-domains.png) | [HTML](../mockups/automation-domains.html) | 자동화 도메인 영역 |
| [caption-agent-hierarchy.png](caption-agent-hierarchy.png) | [HTML](../mockups/caption-agent-hierarchy.html) | 자막 에이전트 계층 |
| [caption-data-flow.png](caption-data-flow.png) | [HTML](../mockups/caption-data-flow.html) | 자막 데이터 흐름 |
| [caption-db-erd.png](caption-db-erd.png) | [HTML](../mockups/caption-db-erd.html) | 자막 DB ERD |
| [data-flow.png](data-flow.png) | [HTML](../mockups/data-flow.html) | 데이터 흐름도 |
| [graphics-automation.png](graphics-automation.png) | [HTML](../mockups/graphics-automation.html) | 그래픽 자동화 |
| [integration.png](integration.png) | [HTML](../mockups/integration.html) | 시스템 통합 |
| [workflow-architecture.png](workflow-architecture.png) | [HTML](../mockups/workflow-architecture.html) | 워크플로우 아키텍처 |

## 자막 이미지

`captions/` 폴더에는 Google Slides에서 추출한 자막 요소 이미지가 있습니다.

### 명명 규칙

```
lv-caption-{슬라이드번호}-{구성요소명}[-{변형번호}].png
```

예시:
- `lv-caption-41-chip-flow-graphic.png` - 기본 버전
- `lv-caption-41-chip-flow-graphic-2.png` - 변형 2

### 슬라이드 범위

- 슬라이드 41-62: 토너먼트 그래픽 요소
- 각 슬라이드별 다양한 변형 포함 (애니메이션 프레임 등)

## 이미지 생성

다이어그램 이미지는 다음 스크립트로 생성됩니다:

```powershell
python scripts/capture_prd_diagrams.py
```
