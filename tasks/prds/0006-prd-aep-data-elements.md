# PRD-0006: AEP 기반 데이터 요소 명세서

| 항목 | 내용 |
|------|------|
| **문서 ID** | PRD-0006 |
| **제목** | AEP 기반 데이터 요소 명세서 |
| **버전** | 1.0.0 |
| **작성일** | 2026-01-09 |
| **상태** | Draft |

---

## 목차

| Part | 제목 | 파일 |
|------|------|------|
| 1 | [Overview](0006/01-overview.md) | 목적, 범위, 목표 |
| 2 | [Data Sources](0006/02-data-sources.md) | 데이터 소스 분류 |
| 3 | [Caption Fields](0006/03-caption-fields.md) | 자막별 데이터 필드 명세 (핵심) |
| 4 | [DB Mapping](0006/04-db-mapping.md) | wsop 스키마 매핑 |
| 5 | [Input Guide](0006/05-input-guide.md) | CSV 템플릿 및 입력 가이드 |

---

## 요약

GFX JSON 데이터를 제외한 **WSOP+ CSV** 및 **수기 입력** 데이터에 대해,
실제 AEP 파일(CyprusDesign.aep)의 동적 레이어 분석 결과를 기반으로
26개 자막 유형별 필요 데이터 필드를 정의합니다.

### 범위

| 포함 | 제외 |
|------|------|
| WSOP+ CSV 데이터 | pokerGFX JSON (GFX 실시간 데이터) |
| 수기 입력 데이터 | AEP 스키마 설계 (다른 프로젝트) |
| AEP 동적 레이어 매핑 | 렌더링 파이프라인 |

### AEP 분석 결과

- **원본**: `C:\claude\automation_ae\templates\CyprusDesign\CyprusDesign.aep`
- **콤포지션**: 58개
- **텍스트 레이어**: 1,397개
- **자막 콤포지션**: 18개 식별

---

## 관련 문서

| PRD | 제목 | 관계 |
|-----|------|------|
| PRD-0001 | Broadcast Graphics | 26개 자막 유형 정의 |
| PRD-0003 | Caption Workflow | 데이터 수집 워크플로우 |
| PRD-0004 | Caption Database Schema | wsop 스키마 설계 |

---

## Changelog

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-01-09 | 초안 작성 |
