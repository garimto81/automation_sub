# Part 1: Overview

## 1.1 목적

**AEP 동적 레이어 분석 결과를 기반으로 26개 자막 유형별 필요 데이터 필드를 정의**

WSOP Broadcast Graphics 시스템에서 자막 렌더링에 필요한 데이터 요소를 명확히 정의하여:
1. 데이터 입력 담당자가 어떤 데이터를 준비해야 하는지 파악
2. DB 스키마와 AEP 레이어 간의 정확한 매핑 제공
3. CSV 템플릿 및 수기 입력 UI 설계 기반 제공

---

## 1.2 범위

### 포함

| 데이터 소스 | 설명 | 담당 |
|------------|------|------|
| **WSOP+ CSV** | 대회 정보, 블라인드, 상금, 플레이어 칩 (Other Tables) | Data Manager |
| **수기 입력** | 프로필, 해설자, 일정, Feature Table 구성 | PA/PD/Production |

### 제외

| 데이터 소스 | 이유 |
|------------|------|
| **pokerGFX JSON** | GFX 실시간 데이터 - PRD-0004에서 별도 처리 |
| **AEP 스키마 설계** | automation_ae 프로젝트에서 별도 처리 |

---

## 1.3 AEP 분석 결과 요약

### 원본 파일

- **경로**: `C:\claude\automation_ae\templates\CyprusDesign\CyprusDesign.aep`
- **분석 결과**: `C:\claude\automation_ae\templates\CyprusDesign\analysis\`

### 통계

| 항목 | 수량 |
|------|------|
| 총 콤포지션 | 58개 |
| 총 Footage | 294개 |
| 텍스트 레이어 | 1,397개 |
| 자막 콤포지션 | 18개 |

### 식별된 자막 콤포지션

| # | 콤포지션명 | 자막 유형 | 텍스트 레이어 |
|---|-----------|----------|-------------|
| 1 | Feature Table Leaderboard MAIN | Feature Table LB | 42개 |
| 2 | Feature Table Leaderboard SUB | Feature Table LB (서브) | 41개 |
| 3 | _MAIN Mini Chip Count | Mini Chip Counts | 21개 |
| 4 | _SUB_Mini Chip Count | Mini Chip Counts (서브) | 21개 |
| 5 | Payouts | Payouts | 31개 |
| 6 | _Mini Payout | Mini Payouts | 29개 |
| 7 | Event info | Event Info | 10개 |
| 8 | Broadcast Schedule | Broadcast Schedule | 23개 |
| 9 | Commentator | Commentator Profile | 8개 |
| 10 | Location | Venue/Location | 2개 |
| 11 | Chip Flow | Chip Flow | 15개 |
| 12 | Chip Comparison | Chip Comparison | 4개 |
| 13 | Chip VPIP | VPIP Stats | 3개 |
| 14 | Chips In Play x3/x4 | Chips In Play | 4-5개 |
| 15 | Elimination | Elimination Banner | 2개 |
| 16 | At Risk of Elimination | At Risk | 1개 |
| 17 | NAME / NAME 1줄 / NAME 2줄 / NAME 3줄+ | Player Profile | 2개 |
| 18 | Block Transition Level-Blinds | Blind Level | 12개 |
| 19 | Event name | Event Name | 2개 |

---

## 1.4 목표

### 주요 산출물

1. **자막별 데이터 필드 명세서** (Part 3)
   - 각 콤포지션의 동적 레이어 목록
   - 필요 데이터 필드 및 타입
   - 데이터 소스 (CSV/수기)

2. **DB 매핑 테이블** (Part 4)
   - AEP 레이어 → wsop 스키마 테이블 매핑
   - 필드별 변환 규칙

3. **입력 가이드** (Part 5)
   - CSV 템플릿 정의
   - 수기 입력 필드 목록

### 성공 기준

| 기준 | 목표 |
|------|------|
| 자막 커버리지 | 18개 AEP 콤포지션 100% 매핑 |
| 필드 정의율 | 모든 동적 레이어에 대해 DB 필드 매핑 |
| CSV 템플릿 | 주요 자막 유형별 템플릿 제공 |

---

## 1.5 관련 문서

| 문서 | 설명 | 참조 |
|------|------|------|
| PRD-0001 | 26개 자막 유형 디자인 | 자막 유형 정의 |
| PRD-0003 | 데이터 수집 워크플로우 | 데이터 소스 분류 |
| PRD-0004 | Caption Database Schema | wsop 스키마 테이블 |
| AEP 분석 파일 | CyprusDesign 분석 결과 | 동적 레이어 목록 |

---

## 1.6 용어 정의

| 용어 | 설명 |
|------|------|
| **동적 레이어** | AEP에서 데이터 바인딩으로 내용이 변경되는 레이어 |
| **텍스트 레이어** | 플레이어 이름, 칩 수량 등 텍스트 데이터 |
| **Footage 레이어** | 국기 이미지, 프로필 사진 등 미디어 데이터 |
| **WSOP+ CSV** | WSOP+ 시스템에서 내보내는 대회 데이터 CSV |
| **수기 입력** | 운영자가 직접 입력하는 데이터 |
