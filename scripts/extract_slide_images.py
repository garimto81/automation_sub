"""
Google Slides 이미지 추출 스크립트

슬라이드에 삽입된 이미지만 추출 (슬라이드 전체 캡쳐 X)
"""
import os
import re
import requests
from pathlib import Path
from typing import Dict, List, Optional
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build

# 대상 프레젠테이션
PRESENTATIONS = {
    'lv': {
        'id': '1UObWgwlDzLA5ucI4Km9DuKNz7U_KQ8lc6aszoLgHv9g',
        'name': '2026 WSOP LV',
        'prefix': 'lv'
    },
    'sc': {
        'id': '1QSIWvvdksgSmRA1oXyn0_ZIRFhOtVd5PSCQ6NeirhZs',
        'name': '2025 WSOP SC Cyprus',
        'prefix': 'sc'
    }
}

# 출력 디렉토리
OUTPUT_DIR = Path(__file__).parent.parent / 'docs' / 'images' / 'slides'

# Google API 스코프
SCOPES = [
    'https://www.googleapis.com/auth/presentations.readonly',
    'https://www.googleapis.com/auth/drive.readonly'
]


def get_credentials() -> Optional[Credentials]:
    """Google API 인증 정보 가져오기"""
    # 환경변수에서 인증 파일 경로 가져오기
    creds_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS') or \
                 os.environ.get('GOOGLE_SHEETS_CREDENTIALS')

    if creds_path and Path(creds_path).exists():
        return Credentials.from_service_account_file(creds_path, scopes=SCOPES)

    # 기본 경로 시도
    default_paths = [
        Path('D:/AI/claude01/json/service_account_key.json'),  # 프로젝트 기본 키
        Path.home() / '.config' / 'gcloud' / 'application_default_credentials.json',
        Path('credentials.json'),
        Path('service_account.json'),
    ]

    for path in default_paths:
        if path.exists():
            return Credentials.from_service_account_file(str(path), scopes=SCOPES)

    print("ERROR: Google API 인증 파일을 찾을 수 없습니다.")
    print("GOOGLE_APPLICATION_CREDENTIALS 환경변수를 설정하거나")
    print("credentials.json 파일을 현재 디렉토리에 배치하세요.")
    return None


def sanitize_filename(name: str) -> str:
    """파일명으로 사용할 수 있도록 정리"""
    # 특수문자 제거
    name = re.sub(r'[<>:"/\\|?*]', '', name)
    # 공백을 언더스코어로
    name = re.sub(r'\s+', '-', name)
    # 소문자로
    name = name.lower()
    # 연속 하이픈 정리
    name = re.sub(r'-+', '-', name)
    return name.strip('-')


def extract_slide_title(slide: Dict) -> str:
    """슬라이드에서 제목 추출 (placeholder + 첫 번째 큰 텍스트)"""
    # 1. 제목 placeholder 찾기
    for element in slide.get('pageElements', []):
        shape = element.get('shape', {})
        placeholder = shape.get('placeholder', {})

        if placeholder.get('type') in ['TITLE', 'CENTERED_TITLE']:
            text_elements = shape.get('text', {}).get('textElements', [])
            for te in text_elements:
                text_run = te.get('textRun', {})
                content = text_run.get('content', '').strip()
                if content:
                    return content

    # 2. 첫 번째 큰 텍스트 박스에서 제목 추출 (상단에 위치한 것)
    text_elements_with_pos = []
    for element in slide.get('pageElements', []):
        shape = element.get('shape', {})
        text_content = shape.get('text', {})
        if not text_content:
            continue

        # 위치 정보
        transform = element.get('transform', {})
        y_pos = transform.get('translateY', 999999)

        # 텍스트 추출
        for te in text_content.get('textElements', []):
            text_run = te.get('textRun', {})
            content = text_run.get('content', '').strip()
            if content and len(content) > 3:  # 짧은 텍스트 제외
                text_elements_with_pos.append((y_pos, content))

    # 상단에 있는 텍스트를 제목으로 사용
    if text_elements_with_pos:
        text_elements_with_pos.sort(key=lambda x: x[0])
        return text_elements_with_pos[0][1]

    return ''


def extract_images_from_presentation(
    service,
    presentation_id: str,
    prefix: str,
    output_dir: Path
) -> List[Dict]:
    """프레젠테이션에서 모든 이미지 추출"""

    # 프레젠테이션 정보 가져오기
    presentation = service.presentations().get(
        presentationId=presentation_id
    ).execute()

    title = presentation.get('title', 'Untitled')
    slides = presentation.get('slides', [])

    print(f"\n=== {title} ===")
    print(f"슬라이드 수: {len(slides)}")

    extracted = []
    image_count = 0

    for slide_idx, slide in enumerate(slides, 1):
        slide_title = extract_slide_title(slide)

        for element in slide.get('pageElements', []):
            # 이미지 요소 찾기
            image = element.get('image')
            if not image:
                continue

            # 이미지 URL 가져오기
            content_url = image.get('contentUrl')
            if not content_url:
                continue

            image_count += 1

            # 파일명 생성
            if slide_title:
                base_name = sanitize_filename(slide_title)
            else:
                base_name = f"slide-{slide_idx}"

            # 같은 슬라이드에 여러 이미지가 있을 경우
            filename = f"{prefix}-{base_name}"

            # 중복 체크 및 번호 추가
            final_path = output_dir / f"{filename}.png"
            counter = 1
            while final_path.exists() or any(e['filename'] == final_path.name for e in extracted):
                final_path = output_dir / f"{filename}-{counter}.png"
                counter += 1

            # 이미지 다운로드
            try:
                response = requests.get(content_url, timeout=30)
                response.raise_for_status()

                # 파일 크기로 필터링 (100KB 미만 = 아이콘/로고, 제외)
                MIN_FILE_SIZE = 100 * 1024  # 100KB
                if len(response.content) < MIN_FILE_SIZE:
                    continue

                # 저장
                with open(final_path, 'wb') as f:
                    f.write(response.content)

                size_kb = len(response.content) / 1024
                print(f"  [{slide_idx}] {final_path.name} ({size_kb:.0f}KB)")

                extracted.append({
                    'slide_index': slide_idx,
                    'slide_title': slide_title,
                    'filename': final_path.name,
                    'path': str(final_path),
                    'size': len(response.content)
                })

            except Exception as e:
                print(f"  [{slide_idx}] ERROR: {e}")

    print(f"총 {len(extracted)}개 이미지 추출 완료")
    return extracted


def main():
    """메인 함수"""
    print("Google Slides 이미지 추출 시작...")

    # 인증
    creds = get_credentials()
    if not creds:
        return

    # 서비스 생성
    service = build('slides', 'v1', credentials=creds)

    # 출력 디렉토리 생성
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 각 프레젠테이션에서 이미지 추출
    all_extracted = {}

    for key, pres in PRESENTATIONS.items():
        try:
            extracted = extract_images_from_presentation(
                service,
                pres['id'],
                pres['prefix'],
                OUTPUT_DIR
            )
            all_extracted[key] = extracted
        except Exception as e:
            print(f"ERROR ({pres['name']}): {e}")

    # 결과 요약
    print("\n" + "=" * 50)
    print("추출 완료 요약")
    print("=" * 50)

    total = 0
    for key, extracted in all_extracted.items():
        pres = PRESENTATIONS[key]
        print(f"{pres['name']}: {len(extracted)}개")
        total += len(extracted)

    print(f"\n총 {total}개 이미지 추출")
    print(f"저장 위치: {OUTPUT_DIR}")


if __name__ == '__main__':
    main()
