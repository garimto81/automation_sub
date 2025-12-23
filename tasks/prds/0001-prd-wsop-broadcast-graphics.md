# PRD: WSOP Broadcast Graphics System

**PRD Number**: PRD-0001
**Version**: 2.0
**Date**: 2025-12-23
**Status**: Draft

### Source Documents
| Event | Document |
|-------|----------|
| 2026 WSOP LV | [Production Plan](https://docs.google.com/presentation/d/1UObWgwlDzLA5ucI4Km9DuKNz7U_KQ8lc6aszoLgHv9g/) |
| 2025 WSOP SC Cyprus | [Production Plan (실무)](https://docs.google.com/presentation/d/1QSIWvvdksgSmRA1oXyn0_ZIRFhOtVd5PSCQ6NeirhZs/) |

---

## 1. Purpose

WSOP 포커 토너먼트의 YouTube Live 방송을 위한 **실시간 그래픽 시스템**을 개발합니다. 토너먼트 진행 상황, 플레이어 정보, 칩 흐름 등을 시각적으로 전달하여 시청자 경험을 극대화합니다.

### 1.1 Goals
- 실시간 토너먼트 데이터를 방송 그래픽으로 변환
- ViewPoint 제공 중심의 정보 전달 (단순 나열 X)
- OBS/vMix 연동 가능한 웹 기반 그래픽 출력
- **AI 활용 자동화** (모니터링, 파일 전송, 시트 공유)
- **Virtual Table + Soft Contents 통합**

### 1.2 Non-Goals
- 영상 편집/인코딩 시스템
- 방송 송출 시스템 (OBS/vMix 사용)
- 가상 테이블 3D 렌더링 (별도 프로젝트)

---

## 2. Target Users

| 사용자 | 역할 | 니즈 |
|--------|------|------|
| **PD/디렉터** | 그래픽 호출 | 빠른 그래픽 전환, 단축키 |
| **오퍼레이터** | 데이터 입력 | 직관적 UI, 실시간 반영 |
| **Data Manager** | 데이터 관리 | RFID 연동, 시트 자동화 |
| **시청자** | 정보 소비 | 명확한 정보, 시각적 임팩트 |

---

## 3. Content Strategy (Day별 전략)

### 3.1 Soft Contents vs Virtual Table 비율

```
Day 1 (예선)     ████████████████████░░  소프트 90% : Virtual 10%
Day 2 (Regi Close) ██████████████░░░░░░░░  소프트 70% : Virtual 30%
Day 3 (ITM/Bubble)  ████████████░░░░░░░░░░  소프트 60% : Virtual 40%
Day 4 (본게임)    ██████████░░░░░░░░░░░░  소프트 50% : Virtual 50%
Final Day        ████░░░░░░░░░░░░░░░░░░  소프트 20% : Virtual 80%
```

### 3.2 Day별 콘텐츠 Focus

| Day | Focus | 주요 콘텐츠 |
|-----|-------|------------|
| **Day 1** | 캐릭터 빌딩 | 키플레이어 소개 (1시간당 ~10명), 스토리 빌드업 |
| **Day 2** | 스택 양극화 | 키플레이어 업데이트, 숏스택 쇼다운(VT), 탈락/리바인 |
| **Day 3** | 버블 집중 | 버블 직전 Key Player 쇼다운, 탈락자, 더블업 |
| **Day 4** | 스토리 고조 | 칩리더/Qualifier/유명인 집중, 빅핸드(VT), 페이점프 |
| **Final** | 결말 | Virtual Table 중심, 우승자 스토리 마무리 |

---

## 4. Core Features

### 4.1 Leaderboard System
**Priority**: High | **Effort**: High

#### 4.1.1 Tournament Leaderboard (Overall)
- 전체 참가자 순위 (칩 기준)
- **스크롤 지원** - 많은 플레이어 표시
- Day별 표시 기준:
  - Day 1 종료: Day 2 진출 인원 전부
  - Day 2 시작: TOP 30 + WSOP+ 앱 광고
  - Bubble 직전: Bottom 20 (Notable 있을 때)
  - ITM 후: 전체 (Top 50)

#### 4.1.2 Feature Table Leaderboard
![Feature Table Leaderboard](../images/slides/sc-feature-lb-2t.png)

- **2 Tables 버전**: 이름/국적/칩/BB/Percentage
- **1 Table 버전**: 단일 테이블 상세 뷰
- 프로필 이미지, 국적, 칩 카운트
- BB(Big Blind) 환산 표시

#### 4.1.3 Mini Chip Counts ⭐ NEW
![Mini Chip Counts](../images/slides/sc-mini-chips.png)
- 플레이어 좌측/우측 공간 활용
- **일반형**: 기본 칩 표시
- **강조형 (Highlights)**: 주목 플레이어
- **Pot Winner**: 팟 획득 시 표시

#### 4.1.4 Payouts
- 상금 구조 테이블 (1st-9th)
- 현재 버블 라인 강조
- ITM(In The Money) 표시

#### 4.1.5 Mini Payouts ⭐ NEW
- 플레이어 좌측/우측 공간 활용
- **일반형**: 현재 상금 구조
- **강조형**: 다음 페이점프
- **탈락 선수 Payout**: 탈락 시 상금 표시

---

### 4.2 Player/Game Statistics
**Priority**: High | **Effort**: Medium

#### 4.2.1 Chip Comparison ⭐ NEW
![Chip Comparison](../images/slides/sc-chip-comparison.png)

- 플레이어 좌측/우측 공간 필요
- 보유 스택 비율 시각화
- 2인 이상 비교 지원

#### 4.2.2 Chip Flow
![Chip Flow](../images/slides/lv-chip-flow.png)

> "토너먼트 레귤러 입장에서 가장 참고할 가치가 높은 정보"

- 플레이어 중앙 하단 공간
- **Last N Hands** 기준 표시
- X축: Hand Number, Y축: Avg% 대비

#### 4.2.3 Chips In Play (Chip Denomination) ⭐ NEW
- 칩스택 좌측/우측 공간
- **표시 타이밍**: 게임 시작 / Break 후 3핸드 이내

#### 4.2.4 VPIP / PFR Stats ⭐ NEW
![VPIP Stats](../images/slides/lv-vpip.png)

- 플레이어 중앙 하단 공간
- **VPIP**: <10% 또는 >45% 극단적 기준
- **PFR**: Pre-Flop Raise 비율

---

### 4.3 Player Info System
**Priority**: High | **Effort**: Medium

#### 4.3.1 Bottom Center Overlay ⭐ NEW
![Bottom Center Overlay](../images/slides/sc-player-overlay.png)

- 플레이어 중앙 하단 공간
- **Player Profile**: 기본 정보
- **Elimination**: 탈락 정보
- **Current Stack**: 현재 칩
- **ETC**: 기타 정보

#### 4.3.2 Player Intro Card
- 플레이어 입장/소개 시 사용
- 이름, 국적, 주요 성적
- WSOP 브레이슬릿 수, 총 상금

#### 4.3.3 At Risk of Elimination ⭐ NEW
![At Risk of Elimination](../images/slides/sc-at-risk.png)

- 플레이어 중앙 하단 공간
- **탈락 시 Payout 표기** - 긴장감 제공

#### 4.3.4 Heads-Up Comparison
![Heads-Up Comparison](../images/slides/lv-heads-up.png)

> ViewPoint 제공이 Priority - 단순 정보 나열 X

---

### 4.4 Event Graphics
**Priority**: Medium | **Effort**: Low

| 그래픽 | 배경 | 정보 |
|--------|------|------|
| **Broadcast Schedule** | Tournament Hall | 방송 시간, 이벤트명 |
| **Tournament Info** | Tournament Hall | Buy-in, Prize Pool, Entrants, Remaining, Places Paid, Min Cash |
| **Event Name** | Tournament Hall | 이벤트명 |
| **Location/Venue** | Drone Shot | 호텔 전경 |
| **Commentator Profile** | Tournament Hall | 사진, 이름 |

---

### 4.5 Transition System
**Priority**: Medium | **Effort**: Medium

| Type | 용도 | 사용 빈도 |
|------|------|----------|
| **메인 트랜지션** | Feature Table → Feature Table | 높음 |
| **Hall shot + Dissolve** | Feature Table 간 이동 | 낮음 (블락과 겹침) |
| **Virtual Table Transition** | Feature ↔ Virtual Table | 중간 |
| **Stinger** | 플레이어 소개/업데이트 | 높음 |
| **Blind Level** | 블라인드 레벨 변경 시 | 레벨마다 |

#### Blind Level Graphic
![Blinds Up](../images/slides/lv-blinds-up.png)

- 현재 블라인드 레벨
- 이전 블라인드
- 다음 블라인드

---

### 4.6 Soft Contents ⭐ NEW
**Priority**: High | **Effort**: High

> 피처테이블 외부의 스토리를 전달하는 콘텐츠

#### 4.6.1 Player 소개/업데이트
- Outer Table 플레이어 소개
- **지속적 업데이트**로 F/up 가능
- Feature Table로의 스토리 빌드업

#### 4.6.2 Hand (RFID)
- **편집으로 RFID 추가** - 집중도 향상
- 빅핸드 하이라이트

#### 4.6.3 Interview
| Type | 특징 |
|------|------|
| **Formal** | 정식 인터뷰 |
| **Casual** | Liv Boeree 스타일, 노림수 있는 인터뷰 |

#### 4.6.4 Special Moment
- 현장 BTS (Behind The Scenes)
- 시청자 흥미 유발 영상

---

## 5. Technical Requirements

### 5.1 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Frontend (React)                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │Leaderboard│ │Statistics│ │PlayerInfo│ │ Soft     │          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                        │
│  │ Event    │ │Transition│ │ Control  │                        │
│  └──────────┘ └──────────┘ └──────────┘                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                        WebSocket/SSE
                              │
┌─────────────────────────────────────────────────────────────────┐
│                       Backend (FastAPI)                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │GraphicAPI│ │ DataSync │ │ Control  │ │   AI     │          │
│  │          │ │ (RFID)   │ │          │ │Automation│          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
               PostgreSQL          Google Sheets
               (Main DB)           (공유 시트)
```

### 5.2 Technology Stack

| Layer | Technology | Reason |
|-------|------------|--------|
| Frontend | React + TypeScript | 컴포넌트 재사용, 타입 안전성 |
| Animation | Framer Motion | 부드러운 전환 효과 |
| Styling | Tailwind CSS | 빠른 스타일링 |
| Backend | FastAPI | 비동기 처리, WebSocket |
| Database | PostgreSQL | 관계형 데이터 |
| Real-time | WebSocket | 실시간 업데이트 |
| AI/Automation | Python + OpenAI | 모니터링 자동화 |
| Sheet Sync | Google Sheets API | 파트별 시트 공유 |

### 5.3 OBS Integration

```
Browser Source URL:
http://localhost:3000/graphics/{graphic_type}

Examples:
- /graphics/leaderboard-tournament
- /graphics/leaderboard-feature?tables=2
- /graphics/chip-comparison
- /graphics/chip-flow
- /graphics/player-profile/{playerId}
- /graphics/at-risk/{playerId}
- /graphics/blind-level
- /graphics/transition/{type}
```

---

## 6. Data Schema

### 6.1 Tournament
```typescript
interface Tournament {
  id: string
  name: string
  event: 'WSOP_LV' | 'WSOP_SC_CYPRUS' | string
  buyIn: number
  startingChips: number
  currentLevel: number
  currentDay: number  // Day 1-Final
  blinds: { small: number; big: number; ante: number }
  registeredPlayers: number
  remainingPlayers: number
  prizePool: number
  payouts: Payout[]
  bubbleLine: number
  isITM: boolean
}
```

### 6.2 Player
```typescript
interface Player {
  id: string
  name: string
  nationality: string  // ISO 3166-1 alpha-2
  photoUrl?: string
  chips: number
  seatNumber: number
  tableNumber: number
  isFeatureTable: boolean
  stats: PlayerStats
  chipHistory: ChipHistoryEntry[]
}

interface PlayerStats {
  wsopBracelets: number
  totalEarnings: number
  finalTables: number
  vpip: number      // Voluntarily Put $ In Pot
  pfr: number       // Pre-Flop Raise
  handsPlayed: number
}

interface ChipHistoryEntry {
  handNumber: number
  chips: number
  timestamp: Date
}
```

### 6.3 Hand (RFID)
```typescript
interface Hand {
  id: string
  handNumber: number
  tableNumber: number
  players: HandPlayer[]
  communityCards: Card[]
  potSize: number
  winner?: string
  timestamp: Date
}

interface HandPlayer {
  playerId: string
  holeCards?: Card[]  // RFID로 추출
  position: number
  action: 'fold' | 'call' | 'raise' | 'check' | 'all-in'
  betAmount?: number
}
```

---

## 7. User Interface

### 7.1 Control Panel

```
┌───────────────────────────────────────────────────────────┐
│  WSOP Graphics Control                          Day 3 ITM │
├───────────────────────────────────────────────────────────┤
│  [Leaderboard ▼]  [Statistics ▼]  [Player ▼]  [Event ▼]  │
│                                                           │
│  Quick Actions:                                           │
│  [F1] Tournament LB  [F2] Feature LB   [F3] Mini Chips   │
│  [F4] Chip Flow      [F5] At Risk      [F6] Transition   │
│  [F7] Blind Level    [F8] Soft Content [F9] Clear All    │
│                                                           │
│  Player Search: [____________] [Select] [Show Profile]    │
│                                                           │
│  Soft Contents Queue:                                     │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ 1. Player Update: John Doe (Table 5)          [▶]   │ │
│  │ 2. Hand Highlight: AA vs KK (Table 3)         [▶]   │ │
│  │ 3. Interview: Sarah Chen                      [▶]   │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
│  Current: Feature LB (2 Tables)              🟢 LIVE     │
└───────────────────────────────────────────────────────────┘
```

### 7.2 Keyboard Shortcuts

| Key | Action |
|-----|--------|
| F1 | Tournament Leaderboard 토글 |
| F2 | Feature Table Leaderboard 토글 |
| F3 | Mini Chip Counts 토글 |
| F4 | Chip Flow 토글 |
| F5 | At Risk of Elimination 토글 |
| F6 | 트랜지션 실행 |
| F7 | Blind Level 표시 |
| F8 | Soft Content 큐 실행 |
| F9 | 모든 그래픽 숨기기 |
| ESC | 현재 그래픽 숨기기 |

---

## 8. Design Guidelines

### 8.1 통일성 요구사항 ⚠️
> "전체적으로 디자인 통일성 필요"

- **타이틀**: 흰색 통일
- **순위 표기**: 번호만 사용 (st, nd, rd, th 삭제)
  - ❌ `1st`, `2nd`, `3rd`
  - ✅ `1`, `2`, `3`

### 8.2 공간 배치

| 위치 | 그래픽 |
|------|--------|
| **중앙 하단** | Chip Flow, VPIP/PFR, Player Profile, At Risk |
| **좌측/우측** | Chip Comparison, Mini Chip Counts, Mini Payouts, Chips In Play |

---

## 9. Implementation Phases

### Phase 1: Core Foundation
- [ ] 프로젝트 세팅 (React + FastAPI)
- [ ] 데이터베이스 스키마 설계
- [ ] WebSocket 실시간 통신 구현
- [ ] OBS Browser Source 기본 연동
- [ ] Google Sheets API 연동 (자동화)

### Phase 2: Leaderboard System
- [ ] Tournament Leaderboard (스크롤 지원)
- [ ] Feature Table Leaderboard (2 Tables / 1 Table)
- [ ] Mini Chip Counts (일반/강조/Pot Winner)
- [ ] Payouts / Mini Payouts
- [ ] 순위 변동 애니메이션

### Phase 3: Statistics & Player Info
- [ ] Chip Comparison 컴포넌트
- [ ] Chip Flow 차트 (Last N Hands)
- [ ] Chips In Play (Chip Denomination)
- [ ] VPIP / PFR Stats
- [ ] Bottom Center Overlay
- [ ] At Risk of Elimination
- [ ] Heads-Up Comparison

### Phase 4: Event & Transition
- [ ] Broadcast Schedule / Tournament Info
- [ ] Event Name / Location
- [ ] Commentator Profile
- [ ] Blind Level 그래픽
- [ ] 메인 트랜지션 / Stinger
- [ ] Virtual Table Transition

### Phase 5: Soft Contents & Control
- [ ] Player 소개/업데이트 컴포넌트
- [ ] Hand Highlight (RFID 연동)
- [ ] Interview 카드
- [ ] Soft Contents Queue 관리
- [ ] Control Panel UI
- [ ] 키보드 단축키

### Phase 6: AI Automation
- [ ] 모니터링 자동화
- [ ] 파일 전송 자동화 (한국 ↔ 현장)
- [ ] 파트별 시트 공유 자동화
- [ ] 통합 테스트

---

## 10. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| 그래픽 로딩 시간 | < 500ms | Performance API |
| 데이터 지연 | < 2초 | WebSocket latency |
| 시청자 리텐션 | +15% | YouTube Analytics |
| PD 만족도 | 4.5/5 | 설문조사 |
| Soft Contents 활용률 | 30%+ 방송 시간 | 로그 분석 |

---

## 11. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| 실시간 데이터 지연 | High | 로컬 캐싱, 낙관적 업데이트 |
| RFID 데이터 누락 | High | 수동 입력 폴백, 알림 시스템 |
| OBS 호환성 이슈 | Medium | Chromium 기반 테스트, 폴백 지원 |
| 복잡한 애니메이션 성능 | Medium | GPU 가속, will-change 최적화 |
| 다양한 해상도 대응 | Low | 반응형 + 고정 크기 옵션 |

---

## 12. Staff Integration

### Production Team Structure
```
HEAD OF PRODUCTION
├── TECHNICAL DIRECTOR
│   ├── Engineer (transmission)
│   └── Engineer (audio)
├── SR. PRODUCER (Front)
│   ├── Cue Sheet Manager
│   └── PA
├── SR. PRODUCER (Back)
│   ├── PA (graphics)
│   └── Producer (graphics)
│       ├── 2D Motion Designer
│       └── 2D Motion Designer
├── POST DIRECTOR
│   ├── Editor x3
│   └── PA (Monitoring) x3
├── SOFT CONTENTS TEAM ⭐
│   └── TBD
└── PROJECT MANAGER
```

### Graphics Team 역할

| 역할 | 책임 |
|------|------|
| **Producer (graphics)** | 그래픽 호출, 컨트롤 패널 운영 |
| **PA (graphics)** | 데이터 입력, 모니터링 |
| **2D Motion Designer** | 신규 그래픽 제작, 애니메이션 |
| **Data Manager** | RFID 데이터 관리, 시트 동기화 |

---

## 13. Open Questions

1. ~~**데이터 소스**: 칩 카운트/핸드 히스토리 어디서 연동?~~ → RFID 시스템 연동
2. **브랜딩**: WSOP 공식 로고/폰트 사용 권한?
3. **다국어**: 영어 외 지원 필요?
4. **아카이브**: 방송 후 그래픽 데이터 보관?
5. **Soft Contents Team**: 팀 구성 확정 필요
6. **Data Manager**: 역할 정의 필요

---

## Appendix

### A. Reference Materials
- [WSOP Paradise Intro](https://www.youtube.com/watch?v=...)
- [Triton Poker Graphics](https://www.youtube.com/watch?v=...)
- [EPT Broadcast Style](https://www.youtube.com/watch?v=...)
- [ESPN Sports Graphics](https://www.youtube.com/watch?v=...)
- [2023 F1: This is No Ordinary Sport](https://www.youtube.com/watch?v=...) - Intro 참고
- [2024 Olympic Basketball](https://www.youtube.com/watch?v=...) - Opening 참고

### B. Related Documents
- [2026 WSOP LV Production Plan](https://docs.google.com/presentation/d/1UObWgwlDzLA5ucI4Km9DuKNz7U_KQ8lc6aszoLgHv9g/)
- [2025 WSOP SC Cyprus Production Plan](https://docs.google.com/presentation/d/1QSIWvvdksgSmRA1oXyn0_ZIRFhOtVd5PSCQ6NeirhZs/)
- Virtual Table 프로젝트 통합 운영 가이드

### C. Wireframe Mockups

#### C.1 Leaderboard System
![Leaderboard Mockup](../images/leaderboard-mockup.png)
- Tournament Leaderboard (Overall)
- Feature Table Leaderboard (2 Tables)
- Mini Chip Counts (Normal/Highlight/Pot Winner)
- Mini Payouts (Normal/Elimination)

**HTML Source**: [leaderboard.html](../mockups/leaderboard.html)

#### C.2 Player Info System
![Player Info Mockup](../images/player-info-mockup.png)
- Player Intro Card
- Bottom Center Overlay
- At Risk of Elimination
- Elimination Card
- Heads-Up Comparison

**HTML Source**: [player-info.html](../mockups/player-info.html)

#### C.3 Statistics
![Statistics Mockup](../images/statistics-mockup.png)
- Chip Comparison
- Chip Flow (Last N Hands)
- Chips In Play (Chip Denomination)
- VPIP / PFR Stats
- Blind Level

**HTML Source**: [statistics.html](../mockups/statistics.html)


---

**Next Steps**:
1. Open Questions 해결
2. Soft Contents Team 구성
3. `/work PRD-0001` 또는 `/issue create` 로 개발 시작
4. Checklist 업데이트: `docs/checklists/PRD-0001.md`
