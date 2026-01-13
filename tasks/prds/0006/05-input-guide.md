# Part 5: Input Guide (데이터 입력 가이드)

이 문서는 WSOP+ CSV 템플릿과 수기 입력 필드 가이드를 제공합니다.

---

## 5.1 WSOP+ CSV 템플릿

### tournaments.csv

```csv
name,buy_in,prize_pool,registered_players,remaining_players,places_paid,avg_stack
"MAIN EVENT",5300,6860000,1372,8,206,857500
```

| 컬럼 | 타입 | 필수 | 설명 | 예시 |
|------|------|:----:|------|------|
| name | TEXT | ✅ | 대회명 | "MAIN EVENT" |
| buy_in | INTEGER | ✅ | 바이인 (달러) | 5300 |
| prize_pool | INTEGER | ✅ | 총 상금 (달러) | 6860000 |
| registered_players | INTEGER | ✅ | 총 참가자 | 1372 |
| remaining_players | INTEGER | ✅ | 남은 참가자 | 8 |
| places_paid | INTEGER | ✅ | 상금 지급 순위 | 206 |
| avg_stack | INTEGER | ❌ | 평균 스택 (계산 가능) | 857500 |

---

### blind_levels.csv

```csv
level_number,small_blind,big_blind,ante,duration
31,75000,150000,150000,60
32,100000,200000,200000,60
33,125000,250000,250000,60
```

| 컬럼 | 타입 | 필수 | 설명 | 예시 |
|------|------|:----:|------|------|
| level_number | INTEGER | ✅ | 레벨 번호 | 32 |
| small_blind | INTEGER | ✅ | 스몰 블라인드 | 100000 |
| big_blind | INTEGER | ✅ | 빅 블라인드 | 200000 |
| ante | INTEGER | ✅ | 앤티 | 200000 |
| duration | INTEGER | ✅ | 레벨 시간 (분) | 60 |

---

### payouts.csv

```csv
place_start,place_end,amount
1,1,1000000
2,2,670000
3,3,475000
4,4,345000
5,5,250000
6,6,185000
7,7,140000
8,8,107500
9,9,82000
```

| 컬럼 | 타입 | 필수 | 설명 | 예시 |
|------|------|:----:|------|------|
| place_start | INTEGER | ✅ | 순위 시작 | 1 |
| place_end | INTEGER | ✅ | 순위 끝 | 1 |
| amount | INTEGER | ✅ | 상금 (달러) | 1000000 |

---

### players.csv (Other Tables)

```csv
name,nationality,chips,current_rank
"DANIEL REZAEI","AT",22975000,1
"BERNARDO NEVES","PT",15375000,2
"ALI KUBASI","LB",12450000,3
```

| 컬럼 | 타입 | 필수 | 설명 | 예시 |
|------|------|:----:|------|------|
| name | TEXT | ✅ | 플레이어 이름 | "DANIEL REZAEI" |
| nationality | TEXT | ✅ | 국적 (ISO 2) | "AT" |
| chips | INTEGER | ✅ | 현재 칩 | 22975000 |
| current_rank | INTEGER | ❌ | 현재 순위 | 1 |

---

## 5.2 수기 입력 필드

### events (이벤트 정보)

| 필드 | 타입 | 필수 | 설명 | 입력 예시 |
|------|------|:----:|------|----------|
| name | TEXT | ✅ | 이벤트명 | "MAIN EVENT FINAL DAY" |
| series_name | TEXT | ✅ | 시리즈명 | "WSOP SUPER CIRCUIT CYPRUS" |
| year | INTEGER | ✅ | 연도 | 2025 |

**담당**: PD

---

### venues (장소 정보)

| 필드 | 타입 | 필수 | 설명 | 입력 예시 |
|------|------|:----:|------|----------|
| name | TEXT | ✅ | 장소명 | "Merit Royal Diamond Hotel" |
| city | TEXT | ❌ | 도시 | "Kyrenia" |
| country | TEXT | ❌ | 국가 | "Cyprus" |

**담당**: PD

---

### schedules (방송 일정)

| 필드 | 타입 | 필수 | 설명 | 입력 예시 |
|------|------|:----:|------|----------|
| date | DATE | ✅ | 방송 날짜 | "2025-10-16" |
| time_start | TIME | ✅ | 시작 시간 | "17:10" |
| timezone | TEXT | ✅ | 타임존 | "UTC+3" |
| title | TEXT | ✅ | 방송 제목 | "MAIN EVENT DAY 1A" |

**담당**: Production Team

**표시 포맷**:
- date: `Oct 16` 형식
- time: `05:10 PM UTC+3` 형식

---

### commentators (해설자)

| 필드 | 타입 | 필수 | 설명 | 입력 예시 |
|------|------|:----:|------|----------|
| name | TEXT | ✅ | 이름 | "Aaron Paul Kramer" |
| social_handle | TEXT | ✅ | SNS 핸들 | "aaronpaulkramer" |
| photo_url | URL | ✅ | 프로필 사진 | "https://..." |
| credentials | TEXT | ❌ | 직함 | "Poker Commentator" |

**담당**: Production Team

**주의**: social_handle에 `@`를 포함하지 않음 (표시 시 자동 추가)

---

### players_master (플레이어 마스터)

| 필드 | 타입 | 필수 | 설명 | 입력 예시 |
|------|------|:----:|------|----------|
| name | TEXT | ✅ | 이름 | "Daniel Rezaei" |
| nationality | TEXT | ✅ | 국적 (ISO 2) | "AT" |
| photo_url | URL | ❌ | 프로필 사진 | "https://..." |
| bracelets | INTEGER | ❌ | WSOP 브레이슬릿 수 | 2 |

**담당**: Data Manager

---

### feature_tables (Feature Table 구성)

| 필드 | 타입 | 필수 | 설명 | 입력 예시 |
|------|------|:----:|------|----------|
| table_number | INTEGER | ✅ | 테이블 번호 (1=MAIN, 2=SUB) | 1 |
| table_name | TEXT | ❌ | 테이블 이름 | "Final Table" |

**담당**: PD

---

### seat_assignment (좌석 배치)

| 필드 | 타입 | 필수 | 설명 | 입력 예시 |
|------|------|:----:|------|----------|
| player_name | TEXT | ✅ | 플레이어 이름 | "Daniel Rezaei" |
| table_number | INTEGER | ✅ | 테이블 번호 | 1 |
| seat_number | INTEGER | ✅ | 좌석 번호 (1-9) | 5 |

**담당**: PA (현장)

---

## 5.3 국적 코드 참조

### 주요 국적 코드 (ISO 3166-1 alpha-2)

| 국가 | 코드 | Flag 파일명 |
|------|------|------------|
| Austria | AT | Austria.png |
| Australia | AU | Australia.png |
| Belgium | BE | Belgium.png |
| Brazil | BR | Brazil.png |
| Canada | CA | Canada.png |
| China | CN | China.png |
| Cyprus | CY | Cyprus.png |
| Czech Republic | CZ | Czech Republic.png |
| Germany | DE | Germany.png |
| Denmark | DK | Denmark.png |
| Spain | ES | Spain.png |
| France | FR | France.png |
| United Kingdom | GB | Great Britain.png |
| Greece | GR | Greece.png |
| Hungary | HU | Hungary.png |
| Ireland | IE | Ireland.png |
| Israel | IL | Israel.png |
| Italy | IT | Italy.png |
| Japan | JP | Japan.png |
| South Korea | KR | South Korea.png |
| Lebanon | LB | lebanon.png |
| Netherlands | NL | Netherlands.png |
| Poland | PL | Poland.png |
| Portugal | PT | Portugal.png |
| Romania | RO | Romania.png |
| Russia | RU | Russia.png |
| Sweden | SE | Sweden.png |
| Turkey | TR | Turkey.png |
| Ukraine | UA | Ukraine.png |
| United States | US | USA.png |

---

## 5.4 입력 검증 규칙

### 필수 필드 검증

| 데이터 | 검증 규칙 |
|--------|----------|
| 국적 코드 | ISO 2 코드 (2자리 대문자) |
| 칩 수 | 양의 정수 |
| 상금 | 양의 정수 |
| 날짜 | YYYY-MM-DD 형식 |
| 시간 | HH:MM 형식 (24시간) |
| URL | http:// 또는 https:// 시작 |

### 중복 검증

| 테이블 | 유니크 키 |
|--------|----------|
| players_master | name + nationality |
| schedules | date + title |
| commentators | name |

---

## 5.5 입력 워크플로우

### 대회 시작 전 (D-1)

```
1. 이벤트 정보 입력 (PD)
   └─ events: name, series_name, year
   └─ venues: name, city, country

2. 일정 입력 (Production)
   └─ schedules: date, time_start, title (6개)

3. 해설자 입력 (Production)
   └─ commentators: name, social_handle, photo_url (2명)

4. 블라인드 구조 CSV 업로드 (Data Manager)
   └─ blind_levels.csv

5. 상금 구조 CSV 업로드 (Data Manager)
   └─ payouts.csv
```

### 대회 시작 (D-Day)

```
1. 플레이어 마스터 확인 (Data Manager)
   └─ players_master: name, nationality

2. Feature Table 구성 (PD)
   └─ feature_tables: table_number, table_name

3. 좌석 배치 (PA)
   └─ seat_assignment: player_name, seat_number
```

### 대회 진행 중

```
1. 칩 카운트 업데이트 (Data Manager)
   └─ players.csv 업로드 (레벨 종료 시)

2. 좌석 변경 (PA)
   └─ seat_assignment 업데이트 (테이블 변경 시)

3. 탈락자 발생 (자동/Data Manager)
   └─ eliminations (GFX에서 자동 또는 수동)
```

---

## 5.6 샘플 데이터

### mini_main.csv (참조)

```csv
플레이어 이름,스택(bb)
"Lipauka","2,225,000 (56BB)"
"Voronin","1,625,000 (41BB)"
"Vos","1,585,000 (40BB)"
"Kalamar","1,465,000 (37BB)"
"Spataru","1,100,000 (28BB)"
"Lukovic","720,000 (18BB)"
"Tlimisov","345,000 (9BB)"
"Katchalov","120,000 (3BB)"
```

> **참고**: 실제 AEP 템플릿의 샘플 CSV 파일 형식

---

## 5.7 주의사항

### 데이터 충돌 방지

1. **Feature Table 플레이어 칩**: GFX에서 실시간 수신되므로 CSV로 덮어쓰지 않음
2. **Other Table 플레이어 칩**: CSV로만 업데이트
3. **좌석 배치**: PA만 수정 권한

### 포맷 주의

1. **이름**: 따옴표로 감싸기 (쉼표 포함 가능)
2. **숫자**: 쉼표 없이 입력 (포맷은 시스템에서 처리)
3. **국적**: 대문자 2자리 (AT, US, GB 등)

### 업로드 타이밍

1. **blind_levels.csv**: 대회 시작 전 1회
2. **payouts.csv**: 대회 시작 전 1회
3. **players.csv**: 레벨 종료 시마다 (Feature Table 제외)
