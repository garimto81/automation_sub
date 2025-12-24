"""
PRD Google Docs에 이미지 추가
이미지를 Google Drive에 업로드 후 문서에 삽입
"""

import os
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# OAuth 2.0 설정
SCOPES = [
    'https://www.googleapis.com/auth/documents',
    'https://www.googleapis.com/auth/drive'
]

CREDENTIALS_FILE = r'D:\AI\claude01\json\desktop_credentials.json'
TOKEN_FILE = r'D:\AI\claude01\json\token.json'

# PRD 문서 ID
DOC_ID = '1HlhO9FByiF-CmsuLhfvJKLRXV7ohBcKVVJLlULu4tcA'

# 이미지 폴더 경로
IMAGE_BASE = r'D:\AI\claude01\automation_sub\docs\images'

# PRD에 추가할 핵심 이미지 목록 (섹션별 매핑)
IMAGES_TO_ADD = [
    # (이미지 파일명, 문서 내 검색할 텍스트, 이미지 설명)
    ('slides/sc-feature-lb-2t.png', '5.1.2 Feature Table Leaderboard', 'Feature Table Leaderboard (2 Tables)'),
    ('slides/sc-mini-chips.png', '5.1.3 Mini Chip Counts', 'Mini Chip Counts'),
    ('slides/sc-chip-comparison.png', '5.2.1 Chip Comparison', 'Chip Comparison'),
    ('slides/lv-chip-flow.png', '5.2.2 Chip Flow', 'Chip Flow Chart'),
    ('slides/lv-vpip.png', '5.2.4 VPIP / PFR Stats', 'VPIP/PFR Statistics'),
    ('slides/sc-player-overlay.png', '5.3.1 Bottom Center Overlay', 'Bottom Center Overlay'),
    ('slides/sc-at-risk.png', '5.3.3 At Risk of Elimination', 'At Risk of Elimination'),
    ('slides/lv-heads-up.png', '5.3.4 Heads-Up Comparison', 'Heads-Up Comparison'),
    ('slides/lv-blinds-up.png', 'Blind Level Graphic', 'Blind Level Display'),
    ('slides/sc-staff.png', 'PRODUCTION TEAM HIERARCHY', 'Production Team Structure'),
]


def get_credentials():
    """OAuth 2.0 인증"""
    creds = None
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


def upload_image_to_drive(drive_service, file_path, folder_id=None):
    """이미지를 Google Drive에 업로드하고 공개 URL 반환"""
    file_name = os.path.basename(file_path)

    file_metadata = {'name': file_name}
    if folder_id:
        file_metadata['parents'] = [folder_id]

    media = MediaFileUpload(file_path, mimetype='image/png')

    file = drive_service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id, webContentLink, webViewLink'
    ).execute()

    file_id = file.get('id')

    # 공개 권한 설정 (anyone can view)
    drive_service.permissions().create(
        fileId=file_id,
        body={'type': 'anyone', 'role': 'reader'}
    ).execute()

    # 직접 접근 가능한 URL 생성
    image_url = f"https://drive.google.com/uc?id={file_id}"

    return file_id, image_url


def find_text_position(docs_service, doc_id, search_text):
    """문서에서 특정 텍스트의 위치 찾기"""
    document = docs_service.documents().get(documentId=doc_id).execute()
    content = document.get('body').get('content')

    for element in content:
        if 'paragraph' in element:
            paragraph = element['paragraph']
            if 'elements' in paragraph:
                for elem in paragraph['elements']:
                    if 'textRun' in elem:
                        text = elem['textRun'].get('content', '')
                        if search_text in text:
                            # 해당 단락의 끝 위치 반환 (이미지를 그 아래에 삽입)
                            return elem.get('endIndex')
    return None


def insert_image_to_doc(docs_service, doc_id, image_url, position, width=400):
    """문서에 이미지 삽입"""
    requests = [
        {
            'insertInlineImage': {
                'location': {'index': position},
                'uri': image_url,
                'objectSize': {
                    'width': {'magnitude': width, 'unit': 'PT'},
                }
            }
        }
    ]

    try:
        docs_service.documents().batchUpdate(
            documentId=doc_id,
            body={'requests': requests}
        ).execute()
        return True
    except Exception as e:
        print(f"  이미지 삽입 실패: {e}")
        return False


def create_prd_images_folder(drive_service):
    """PRD 이미지용 Drive 폴더 생성"""
    folder_metadata = {
        'name': 'PRD-WSOP-Images',
        'mimeType': 'application/vnd.google-apps.folder'
    }

    folder = drive_service.files().create(
        body=folder_metadata,
        fields='id'
    ).execute()

    return folder.get('id')


def add_images_to_prd():
    """PRD 문서에 이미지 추가"""
    creds = get_credentials()
    docs_service = build('docs', 'v1', credentials=creds)
    drive_service = build('drive', 'v3', credentials=creds)

    print("PRD 문서에 이미지 추가 시작...")
    print(f"문서 ID: {DOC_ID}")

    # 이미지 폴더 생성
    print("\n1. Drive 폴더 생성...")
    folder_id = create_prd_images_folder(drive_service)
    print(f"   폴더 ID: {folder_id}")

    # 이미지 업로드 및 삽입
    print("\n2. 이미지 업로드 및 삽입...")

    uploaded_images = []

    for image_file, search_text, description in IMAGES_TO_ADD:
        image_path = os.path.join(IMAGE_BASE, image_file)

        if not os.path.exists(image_path):
            print(f"   [SKIP] {image_file} - 파일 없음")
            continue

        print(f"\n   처리중: {description}")

        # 이미지 업로드
        try:
            file_id, image_url = upload_image_to_drive(drive_service, image_path, folder_id)
            print(f"   - 업로드 완료: {file_id}")
            uploaded_images.append({
                'description': description,
                'search_text': search_text,
                'image_url': image_url,
                'file_id': file_id
            })
        except Exception as e:
            print(f"   - 업로드 실패: {e}")

    # 문서에 이미지 삽입 (역순으로 - 인덱스 변경 방지)
    print("\n3. 문서에 이미지 삽입...")

    # 각 이미지의 위치 찾기
    positions = []
    for img_info in uploaded_images:
        pos = find_text_position(docs_service, DOC_ID, img_info['search_text'])
        if pos:
            positions.append((pos, img_info))
            print(f"   - '{img_info['description']}' 위치: {pos}")
        else:
            print(f"   - '{img_info['description']}' 텍스트 찾기 실패")

    # 위치 기준 역순 정렬 (뒤에서부터 삽입해야 인덱스 변경 방지)
    positions.sort(key=lambda x: x[0], reverse=True)

    for pos, img_info in positions:
        # 줄바꿈 후 이미지 삽입
        try:
            # 먼저 줄바꿈 추가
            docs_service.documents().batchUpdate(
                documentId=DOC_ID,
                body={'requests': [{
                    'insertText': {
                        'location': {'index': pos},
                        'text': '\n\n'
                    }
                }]}
            ).execute()

            # 이미지 삽입
            success = insert_image_to_doc(docs_service, DOC_ID, img_info['image_url'], pos + 2, width=350)
            if success:
                print(f"   [OK] {img_info['description']}")

        except Exception as e:
            print(f"   [FAIL] {img_info['description']}: {e}")

    print(f"\n완료!")
    print(f"문서 URL: https://docs.google.com/document/d/{DOC_ID}/edit")
    print(f"이미지 폴더: https://drive.google.com/drive/folders/{folder_id}")

    return {
        'doc_id': DOC_ID,
        'folder_id': folder_id,
        'images_count': len(uploaded_images)
    }


if __name__ == '__main__':
    result = add_images_to_prd()
