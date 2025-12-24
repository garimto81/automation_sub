"""
Google Docs 문서 생성 스크립트
OAuth 2.0 인증을 사용하여 Google Docs를 생성합니다.
"""

import os
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# OAuth 2.0 설정
SCOPES = [
    'https://www.googleapis.com/auth/documents',  # Docs 읽기/쓰기
    'https://www.googleapis.com/auth/drive.file'  # 생성한 파일 접근
]

# 절대 경로 (서브 레포에서도 동작)
CREDENTIALS_FILE = r'D:\AI\claude01\json\desktop_credentials.json'
TOKEN_FILE = r'D:\AI\claude01\json\token.json'


def get_credentials():
    """OAuth 2.0 인증 정보 가져오기"""
    creds = None

    # 기존 토큰 확인
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    # 토큰이 없거나 만료된 경우
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)

        # 토큰 저장
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())

    return creds


def create_google_docs(title: str, initial_content: str = None) -> dict:
    """
    Google Docs 문서 생성

    Args:
        title: 문서 제목
        initial_content: 초기 내용 (선택사항)

    Returns:
        생성된 문서 정보 (id, title, url)
    """
    creds = get_credentials()

    # Docs API 서비스 생성
    docs_service = build('docs', 'v1', credentials=creds)

    # 새 문서 생성
    document = docs_service.documents().create(body={'title': title}).execute()

    doc_id = document.get('documentId')
    doc_title = document.get('title')
    doc_url = f"https://docs.google.com/document/d/{doc_id}/edit"

    print(f"문서 생성 완료!")
    print(f"  제목: {doc_title}")
    print(f"  ID: {doc_id}")
    print(f"  URL: {doc_url}")

    # 초기 내용이 있으면 추가
    if initial_content:
        requests = [
            {
                'insertText': {
                    'location': {'index': 1},
                    'text': initial_content
                }
            }
        ]
        docs_service.documents().batchUpdate(
            documentId=doc_id,
            body={'requests': requests}
        ).execute()
        print(f"  초기 내용 추가됨")

    return {
        'id': doc_id,
        'title': doc_title,
        'url': doc_url
    }


if __name__ == '__main__':
    # PRD 제목과 동일하게 문서 생성
    title = "WSOP Broadcast Graphics System"

    # 초기 내용 (PRD 템플릿)
    initial_content = """WSOP Broadcast Graphics System

Product Requirements Document (PRD)

Version: 2.0
Created: 2025-12-24
Status: Draft

---

Overview
이 문서는 WSOP 방송 그래픽 시스템의 요구사항을 정의합니다.

---

Scope
- Tournament Leaderboard
- Feature Table Display
- Player Statistics
- Real-time Updates

---

"""

    result = create_google_docs(title, initial_content)
    print(f"\n브라우저에서 열기: {result['url']}")
