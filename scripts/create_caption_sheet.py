"""
WSOP Caption Types - Google Sheets 자동 생성 스크립트
26개 자막 유형 정보를 Google Sheets에 정리
"""

import os
import sys
import time
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# === OAuth 2.0 설정 ===
SCOPES = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive'
]
CREDENTIALS_FILE = r'C:\claude\json\desktop_credentials.json'
TOKEN_FILE = r'C:\claude\json\token_sheets.json'  # Sheets 전용 토큰
SHEET_TITLE = "WSOP Caption Types - 26개 자막 유형"

# === 26개 자막 유형 데이터 ===
CAPTION_TYPES = [
    # Leaderboard System (5개)
    {
        "id": 1,
        "category": "Leaderboard",
        "name_ko": "토너먼트 리더보드",
        "code": "tournament_leaderboard",
        "data_source": "pokerGFX / WSOP+ CSV",
        "pre": "-",
        "live": "O",
        "auto": "O",
        "trigger": "hand_completed, level_change",
        "db_tables": "players, chip_history",
        "priority": "P0",
        "notes": "전체 참가자 순위 (칩 기준), 스크롤 지원"
    },
    {
        "id": 2,
        "category": "Leaderboard",
        "name_ko": "피처 테이블 LB",
        "code": "feature_table_leaderboard",
        "data_source": "pokerGFX",
        "pre": "-",
        "live": "O",
        "auto": "-",
        "trigger": "feature_table_change",
        "db_tables": "players, player_profiles",
        "priority": "P0",
        "notes": "피처 테이블 플레이어만 표시"
    },
    {
        "id": 3,
        "category": "Leaderboard",
        "name_ko": "미니 칩 카운트",
        "code": "mini_chip_counts",
        "data_source": "pokerGFX / WSOP+ CSV",
        "pre": "-",
        "live": "O",
        "auto": "O",
        "trigger": "chip_update, pot_won",
        "db_tables": "chip_history",
        "priority": "P1",
        "notes": "핸드 중 실시간 칩 변동 표시"
    },
    {
        "id": 4,
        "category": "Leaderboard",
        "name_ko": "페이아웃",
        "code": "payouts",
        "data_source": "WSOP+ CSV",
        "pre": "O",
        "live": "-",
        "auto": "-",
        "trigger": "tournament_start, itm_reached",
        "db_tables": "payouts",
        "priority": "P0",
        "notes": "순위별 상금 구조 (1-9위)"
    },
    {
        "id": 5,
        "category": "Leaderboard",
        "name_ko": "미니 페이아웃",
        "code": "mini_payouts",
        "data_source": "WSOP+ CSV",
        "pre": "O",
        "live": "O",
        "auto": "-",
        "trigger": "elimination, pay_jump",
        "db_tables": "payouts, players",
        "priority": "P1",
        "notes": "현재/다음 상금, 버블 라인 표시"
    },
    # Player Info System (6개)
    {
        "id": 6,
        "category": "Player Info",
        "name_ko": "플레이어 프로필",
        "code": "player_profile",
        "data_source": "수기 입력",
        "pre": "O",
        "live": "O",
        "auto": "-",
        "trigger": "player_featured",
        "db_tables": "players, player_profiles",
        "priority": "P0",
        "notes": "이름, 국적, 사진, 브레이슬릿, 수익"
    },
    {
        "id": 7,
        "category": "Player Info",
        "name_ko": "플레이어 인트로 카드",
        "code": "player_intro_card",
        "data_source": "수기 입력",
        "pre": "O",
        "live": "-",
        "auto": "-",
        "trigger": "player_intro_trigger",
        "db_tables": "player_profiles",
        "priority": "P1",
        "notes": "바이오그래피, 주요 우승 이력"
    },
    {
        "id": 8,
        "category": "Player Info",
        "name_ko": "탈락 위기",
        "code": "at_risk",
        "data_source": "pokerGFX / WSOP+ CSV",
        "pre": "-",
        "live": "O",
        "auto": "O",
        "trigger": "all_in_detected, short_stack",
        "db_tables": "players, payouts",
        "priority": "P0",
        "notes": "올인 감지 시 탈락 위험 표시"
    },
    {
        "id": 9,
        "category": "Player Info",
        "name_ko": "탈락 배너",
        "code": "elimination_banner",
        "data_source": "WSOP+ CSV",
        "pre": "-",
        "live": "O",
        "auto": "-",
        "trigger": "player_eliminated",
        "db_tables": "players",
        "priority": "P0",
        "notes": "탈락 순위, 상금 표시"
    },
    {
        "id": 10,
        "category": "Player Info",
        "name_ko": "코멘테이터 프로필",
        "code": "commentator_profile",
        "data_source": "수기 입력",
        "pre": "O",
        "live": "-",
        "auto": "-",
        "trigger": "broadcast_start",
        "db_tables": "commentators",
        "priority": "P2",
        "notes": "해설자 이름, 사진, 자격"
    },
    {
        "id": 11,
        "category": "Player Info",
        "name_ko": "헤드업 비교",
        "code": "heads_up_comparison",
        "data_source": "pokerGFX / 수기 입력",
        "pre": "O",
        "live": "O",
        "auto": "O",
        "trigger": "heads_up_trigger",
        "db_tables": "player_stats, chip_history",
        "priority": "P1",
        "notes": "2인 통계 비교, 칩 비율"
    },
    # Statistics (5개)
    {
        "id": 12,
        "category": "Statistics",
        "name_ko": "칩 플로우",
        "code": "chip_flow",
        "data_source": "pokerGFX",
        "pre": "-",
        "live": "O",
        "auto": "O",
        "trigger": "hand_completed",
        "db_tables": "chip_history",
        "priority": "P0",
        "notes": "최근 15핸드 칩 변동 라인 차트"
    },
    {
        "id": 13,
        "category": "Statistics",
        "name_ko": "칩 비교",
        "code": "chip_comparison",
        "data_source": "pokerGFX",
        "pre": "-",
        "live": "O",
        "auto": "O",
        "trigger": "showdown_start",
        "db_tables": "chip_history",
        "priority": "P1",
        "notes": "2인 이상 칩 비교, 팟 에퀴티"
    },
    {
        "id": 14,
        "category": "Statistics",
        "name_ko": "칩스 인 플레이",
        "code": "chips_in_play",
        "data_source": "WSOP+ CSV",
        "pre": "O",
        "live": "O",
        "auto": "-",
        "trigger": "level_start, break_end",
        "db_tables": "blind_levels, tournaments",
        "priority": "P2",
        "notes": "칩 단위별 총량 분석"
    },
    {
        "id": 15,
        "category": "Statistics",
        "name_ko": "VPIP 통계",
        "code": "vpip_stats",
        "data_source": "pokerGFX",
        "pre": "-",
        "live": "O",
        "auto": "O",
        "trigger": "stat_threshold_reached",
        "db_tables": "player_stats, hand_actions",
        "priority": "P1",
        "notes": "VPIP, PFR 통계 표시"
    },
    {
        "id": 16,
        "category": "Statistics",
        "name_ko": "칩 스택 바",
        "code": "chip_stack_bar",
        "data_source": "pokerGFX / WSOP+ CSV",
        "pre": "-",
        "live": "O",
        "auto": "O",
        "trigger": "feature_table_update",
        "db_tables": "chip_history, players",
        "priority": "P2",
        "notes": "순위별 칩 스택 막대 차트"
    },
    # Event Graphics (5개)
    {
        "id": 17,
        "category": "Event Graphics",
        "name_ko": "방송 스케줄",
        "code": "broadcast_schedule",
        "data_source": "수기 입력",
        "pre": "O",
        "live": "-",
        "auto": "-",
        "trigger": "show_schedule_trigger",
        "db_tables": "schedules",
        "priority": "P2",
        "notes": "방송 일정표 (날짜, 시간, 채널)"
    },
    {
        "id": 18,
        "category": "Event Graphics",
        "name_ko": "이벤트 정보",
        "code": "event_info",
        "data_source": "WSOP+ CSV / 수기 입력",
        "pre": "O",
        "live": "O",
        "auto": "-",
        "trigger": "tournament_start, level_change",
        "db_tables": "tournaments",
        "priority": "P1",
        "notes": "바이인, 프라이즈풀, 참가자 수"
    },
    {
        "id": 19,
        "category": "Event Graphics",
        "name_ko": "장소/베뉴",
        "code": "venue_location",
        "data_source": "수기 입력",
        "pre": "O",
        "live": "-",
        "auto": "-",
        "trigger": "venue_shot_trigger",
        "db_tables": "venues",
        "priority": "P2",
        "notes": "장소 이름, 도시, 드론샷"
    },
    {
        "id": 20,
        "category": "Event Graphics",
        "name_ko": "토너먼트 정보",
        "code": "tournament_info",
        "data_source": "WSOP+ CSV",
        "pre": "O",
        "live": "O",
        "auto": "-",
        "trigger": "day_start",
        "db_tables": "tournaments, blind_levels",
        "priority": "P1",
        "notes": "이벤트명, 데이, 현재 레벨"
    },
    {
        "id": 21,
        "category": "Event Graphics",
        "name_ko": "이벤트 이름",
        "code": "event_name",
        "data_source": "수기 입력",
        "pre": "O",
        "live": "-",
        "auto": "-",
        "trigger": "event_name_trigger",
        "db_tables": "events",
        "priority": "P2",
        "notes": "이벤트 전체 이름, 스폰서 로고"
    },
    # Transition & L-Bar (5개)
    {
        "id": 22,
        "category": "L-Bar & Transition",
        "name_ko": "블라인드 레벨",
        "code": "blind_level",
        "data_source": "WSOP+ CSV",
        "pre": "-",
        "live": "O",
        "auto": "-",
        "trigger": "level_change",
        "db_tables": "blind_levels",
        "priority": "P0",
        "notes": "현재 레벨, 블라인드, 앤티, 남은 시간"
    },
    {
        "id": 23,
        "category": "L-Bar & Transition",
        "name_ko": "L-Bar (표준)",
        "code": "l_bar_standard",
        "data_source": "WSOP+ CSV",
        "pre": "-",
        "live": "O",
        "auto": "O",
        "trigger": "always_on",
        "db_tables": "tournaments, blind_levels",
        "priority": "P0",
        "notes": "하단 정보바 (블라인드, 남은 좌석, 스케줄)"
    },
    {
        "id": 24,
        "category": "L-Bar & Transition",
        "name_ko": "L-Bar (등록 오픈)",
        "code": "l_bar_regi_open",
        "data_source": "WSOP+ CSV",
        "pre": "-",
        "live": "O",
        "auto": "-",
        "trigger": "registration_open",
        "db_tables": "tournaments",
        "priority": "P1",
        "notes": "등록 오픈 상태, 카운트다운"
    },
    {
        "id": 25,
        "category": "L-Bar & Transition",
        "name_ko": "L-Bar (등록 마감)",
        "code": "l_bar_regi_close",
        "data_source": "WSOP+ CSV",
        "pre": "-",
        "live": "O",
        "auto": "-",
        "trigger": "pre_registration_close",
        "db_tables": "tournaments",
        "priority": "P1",
        "notes": "등록 마감 예정, 최종 참가자 수"
    },
    {
        "id": 26,
        "category": "L-Bar & Transition",
        "name_ko": "트랜지션",
        "code": "transition",
        "data_source": "-",
        "pre": "-",
        "live": "-",
        "auto": "-",
        "trigger": "scene_change, player_highlight",
        "db_tables": "-",
        "priority": "P1",
        "notes": "장면 전환 그래픽, 스팅어"
    },
]

# === 시트 탭 정의 ===
SHEET_TABS = [
    {"name": "Summary", "color": {"red": 0.2, "green": 0.4, "blue": 0.8}},
    {"name": "Leaderboard", "color": {"red": 0.8, "green": 0.2, "blue": 0.2}},
    {"name": "Player Info", "color": {"red": 0.2, "green": 0.6, "blue": 0.2}},
    {"name": "Statistics", "color": {"red": 0.6, "green": 0.4, "blue": 0.8}},
    {"name": "Event Graphics", "color": {"red": 0.8, "green": 0.6, "blue": 0.2}},
    {"name": "L-Bar & Transition", "color": {"red": 0.4, "green": 0.6, "blue": 0.8}},
]

# === 우선순위 색상 ===
PRIORITY_COLORS = {
    "P0": {"red": 0.95, "green": 0.8, "blue": 0.8},   # 연한 빨강
    "P1": {"red": 0.98, "green": 0.9, "blue": 0.8},   # 연한 주황
    "P2": {"red": 0.98, "green": 0.98, "blue": 0.8},  # 연한 노랑
    "P3": {"red": 0.8, "green": 0.95, "blue": 0.8},   # 연한 초록
}


def get_credentials():
    """OAuth 2.0 인증"""
    creds = None

    if not os.path.exists(CREDENTIALS_FILE):
        print(f"오류: {CREDENTIALS_FILE} 파일을 찾을 수 없습니다.")
        print("C:\\claude\\json\\ 경로에 desktop_credentials.json 파일이 있는지 확인하세요.")
        sys.exit(1)

    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)

        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())

    return creds


def api_call_with_retry(func, max_retries=3):
    """API 호출 재시도 (지수 백오프)"""
    for attempt in range(max_retries):
        try:
            return func()
        except HttpError as e:
            if e.resp.status == 429:  # Rate limit
                wait_time = 2 ** attempt
                print(f"  API 할당량 초과. {wait_time}초 후 재시도...")
                time.sleep(wait_time)
            else:
                raise
    raise Exception(f"최대 재시도 횟수 ({max_retries}) 초과")


def create_spreadsheet(service, title):
    """스프레드시트 생성"""
    spreadsheet = {
        'properties': {'title': title},
        'sheets': [{'properties': {'title': tab['name'], 'tabColor': tab['color']}} for tab in SHEET_TABS]
    }

    result = service.spreadsheets().create(body=spreadsheet).execute()
    return result['spreadsheetId'], result['spreadsheetUrl']


def get_sheet_id(service, spreadsheet_id, sheet_name):
    """시트 ID 조회"""
    spreadsheet = service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
    for sheet in spreadsheet['sheets']:
        if sheet['properties']['title'] == sheet_name:
            return sheet['properties']['sheetId']
    return None


def populate_summary_sheet(service, spreadsheet_id):
    """Summary 시트 데이터 입력"""
    # 헤더 행
    header = ["#", "카테고리", "자막명 (한글)", "영문 코드", "데이터 소스",
              "Pre", "Live", "Auto", "트리거 이벤트", "DB 테이블", "우선순위", "비고"]

    # 데이터 행
    rows = [header]
    for caption in CAPTION_TYPES:
        rows.append([
            caption["id"],
            caption["category"],
            caption["name_ko"],
            caption["code"],
            caption["data_source"],
            caption["pre"],
            caption["live"],
            caption["auto"],
            caption["trigger"],
            caption["db_tables"],
            caption["priority"],
            caption["notes"]
        ])

    # 데이터 입력
    service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range="Summary!A1",
        valueInputOption="USER_ENTERED",
        body={"values": rows}
    ).execute()

    return len(rows)


def populate_category_sheets(service, spreadsheet_id):
    """카테고리별 시트 데이터 입력"""
    categories = {
        "Leaderboard": [],
        "Player Info": [],
        "Statistics": [],
        "Event Graphics": [],
        "L-Bar & Transition": []
    }

    # 카테고리별 분류
    for caption in CAPTION_TYPES:
        categories[caption["category"]].append(caption)

    # 각 시트에 데이터 입력
    header = ["자막명", "영문 코드", "데이터 소스", "Pre", "Live", "Auto",
              "트리거 이벤트", "핵심 DB 테이블", "우선순위", "비고"]

    for category, captions in categories.items():
        rows = [header]
        for c in captions:
            rows.append([
                c["name_ko"],
                c["code"],
                c["data_source"],
                c["pre"],
                c["live"],
                c["auto"],
                c["trigger"],
                c["db_tables"],
                c["priority"],
                c["notes"]
            ])

        service.spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range=f"'{category}'!A1",
            valueInputOption="USER_ENTERED",
            body={"values": rows}
        ).execute()


def apply_formatting(service, spreadsheet_id):
    """서식 적용"""
    requests = []

    # 모든 시트에 헤더 서식 적용
    spreadsheet = service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()

    for sheet in spreadsheet['sheets']:
        sheet_id = sheet['properties']['sheetId']

        # 헤더 행 서식 (굵은 글씨, 배경색)
        requests.append({
            "repeatCell": {
                "range": {
                    "sheetId": sheet_id,
                    "startRowIndex": 0,
                    "endRowIndex": 1
                },
                "cell": {
                    "userEnteredFormat": {
                        "backgroundColor": {"red": 0.26, "green": 0.52, "blue": 0.96},
                        "textFormat": {"bold": True, "foregroundColor": {"red": 1, "green": 1, "blue": 1}},
                        "horizontalAlignment": "CENTER"
                    }
                },
                "fields": "userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)"
            }
        })

        # 열 고정 (헤더 행)
        requests.append({
            "updateSheetProperties": {
                "properties": {
                    "sheetId": sheet_id,
                    "gridProperties": {"frozenRowCount": 1}
                },
                "fields": "gridProperties.frozenRowCount"
            }
        })

    # Summary 시트 열 너비 조정
    summary_id = get_sheet_id(service, spreadsheet_id, "Summary")
    column_widths = [40, 120, 160, 200, 140, 50, 50, 50, 220, 180, 80, 300]

    for i, width in enumerate(column_widths):
        requests.append({
            "updateDimensionProperties": {
                "range": {
                    "sheetId": summary_id,
                    "dimension": "COLUMNS",
                    "startIndex": i,
                    "endIndex": i + 1
                },
                "properties": {"pixelSize": width},
                "fields": "pixelSize"
            }
        })

    # 조건부 서식 (우선순위별 색상) - Summary 시트
    for priority, color in PRIORITY_COLORS.items():
        requests.append({
            "addConditionalFormatRule": {
                "rule": {
                    "ranges": [{
                        "sheetId": summary_id,
                        "startRowIndex": 1,
                        "startColumnIndex": 10,
                        "endColumnIndex": 11
                    }],
                    "booleanRule": {
                        "condition": {
                            "type": "TEXT_EQ",
                            "values": [{"userEnteredValue": priority}]
                        },
                        "format": {"backgroundColor": color}
                    }
                },
                "index": 0
            }
        })

    # 배치 업데이트 실행
    service.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id,
        body={"requests": requests}
    ).execute()


def main():
    """메인 실행"""
    print("\n=== WSOP Caption Types 스프레드시트 생성 ===\n")

    # 1. OAuth 인증
    print("1. OAuth 인증 중...")
    creds = get_credentials()
    service = build('sheets', 'v4', credentials=creds)
    print(f"   토큰 로드 완료 ({TOKEN_FILE})")

    # 2. 스프레드시트 생성
    print("\n2. 스프레드시트 생성 중...")
    spreadsheet_id, spreadsheet_url = create_spreadsheet(service, SHEET_TITLE)
    print(f"   제목: {SHEET_TITLE}")
    print(f"   ID: {spreadsheet_id}")

    # 3. 시트 탭 확인
    print("\n3. 시트 탭 생성 완료:")
    for tab in SHEET_TABS:
        print(f"   - {tab['name']}")

    # 4. 데이터 입력
    print("\n4. 데이터 입력 중...")
    row_count = populate_summary_sheet(service, spreadsheet_id)
    print(f"   - Summary: {row_count}행 입력 완료")

    populate_category_sheets(service, spreadsheet_id)
    print("   - 카테고리별 시트 입력 완료")

    # 5. 서식 적용
    print("\n5. 서식 적용 중...")
    apply_formatting(service, spreadsheet_id)
    print("   - 헤더 스타일 적용 완료")
    print("   - 조건부 서식 적용 완료 (P0: 빨강, P1: 주황, P2: 노랑)")
    print("   - 열 너비 조정 완료")

    # 6. 결과 출력
    print("\n=== 완료 ===")
    print(f"스프레드시트 URL: {spreadsheet_url}")

    return {"id": spreadsheet_id, "url": spreadsheet_url}


if __name__ == "__main__":
    main()
