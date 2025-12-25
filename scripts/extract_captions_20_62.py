"""
슬라이드 20-62 자막 요소 추출 스크립트

필터 조정: 100KB -> 5KB (작은 그래픽 요소도 추출)
범위: 슬라이드 20-62만 추출
"""
import os
import re
import sys
import requests
from pathlib import Path
from typing import Dict, List, Optional
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build

# 설정
PRESENTATION_ID = '1UObWgwlDzLA5ucI4Km9DuKNz7U_KQ8lc6aszoLgHv9g'
PRESENTATION_NAME = '2026 WSOP LV'
PREFIX = 'lv-caption'

# 슬라이드 범위 (1-indexed)
SLIDE_START = 20
SLIDE_END = 62

# 출력 디렉토리
OUTPUT_DIR = Path(__file__).parent.parent / 'docs' / 'images' / 'captions'

# 필터 설정 (5KB로 낮춤)
MIN_FILE_SIZE = 5 * 1024  # 5KB

# Google API 스코프
SCOPES = [
    'https://www.googleapis.com/auth/presentations.readonly',
    'https://www.googleapis.com/auth/drive.readonly'
]


def get_credentials() -> Optional[Credentials]:
    """Google API 인증 정보 가져오기"""
    default_paths = [
        Path('D:/AI/claude01/json/service_account_key.json'),
        Path.home() / '.config' / 'gcloud' / 'application_default_credentials.json',
    ]

    for path in default_paths:
        if path.exists():
            return Credentials.from_service_account_file(str(path), scopes=SCOPES)

    print("ERROR: Google API 인증 파일을 찾을 수 없습니다.")
    return None


def sanitize_filename(name: str) -> str:
    """파일명으로 사용할 수 있도록 정리"""
    name = re.sub(r'[<>:"/\\|?*]', '', name)
    name = re.sub(r'\s+', '-', name)
    name = name.lower()
    name = re.sub(r'-+', '-', name)
    return name.strip('-')[:50]  # 최대 50자


def extract_slide_text(slide: Dict) -> str:
    """슬라이드에서 첫 번째 텍스트 추출"""
    texts = []
    for element in slide.get('pageElements', []):
        shape = element.get('shape', {})
        text_content = shape.get('text', {})
        if text_content:
            for te in text_content.get('textElements', []):
                content = te.get('textRun', {}).get('content', '').strip()
                if content and len(content) > 2:
                    texts.append(content)

    return texts[0] if texts else ''


def main():
    """메인 함수"""
    sys.stdout.reconfigure(encoding='utf-8')

    print(f"슬라이드 {SLIDE_START}-{SLIDE_END} 자막 요소 추출")
    print(f"최소 파일 크기: {MIN_FILE_SIZE // 1024}KB")
    print("=" * 60)

    # 인증
    creds = get_credentials()
    if not creds:
        return

    # 서비스 생성
    service = build('slides', 'v1', credentials=creds)

    # 출력 디렉토리 생성
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 프레젠테이션 정보 가져오기
    presentation = service.presentations().get(
        presentationId=PRESENTATION_ID
    ).execute()

    slides = presentation.get('slides', [])
    print(f"전체 슬라이드 수: {len(slides)}")
    print(f"추출 범위: {SLIDE_START}-{SLIDE_END}")
    print()

    extracted = []
    skipped_small = 0
    skipped_no_url = 0

    # 슬라이드 범위 추출
    for slide_idx in range(SLIDE_START - 1, min(SLIDE_END, len(slides))):
        slide = slides[slide_idx]
        slide_num = slide_idx + 1
        slide_text = extract_slide_text(slide)

        # 슬라이드별 이미지 카운터
        img_counter = 0

        for element in slide.get('pageElements', []):
            image = element.get('image')
            if not image:
                continue

            content_url = image.get('contentUrl')
            if not content_url:
                skipped_no_url += 1
                continue

            img_counter += 1

            # 파일명 생성
            if slide_text:
                base_name = sanitize_filename(slide_text)
            else:
                base_name = f"slide-{slide_num}"

            filename = f"{PREFIX}-{slide_num:02d}-{base_name}"
            if img_counter > 1:
                filename = f"{filename}-{img_counter}"

            final_path = OUTPUT_DIR / f"{filename}.png"

            # 이미지 다운로드
            try:
                response = requests.get(content_url, timeout=30)
                response.raise_for_status()

                size = len(response.content)
                size_kb = size / 1024

                # 파일 크기 필터링
                if size < MIN_FILE_SIZE:
                    skipped_small += 1
                    print(f"  [{slide_num}] SKIP: {size_kb:.1f}KB < {MIN_FILE_SIZE//1024}KB")
                    continue

                # 저장
                with open(final_path, 'wb') as f:
                    f.write(response.content)

                print(f"  [{slide_num}] {final_path.name} ({size_kb:.0f}KB) - {slide_text[:30]}")

                extracted.append({
                    'slide': slide_num,
                    'title': slide_text,
                    'filename': final_path.name,
                    'size_kb': size_kb
                })

            except Exception as e:
                print(f"  [{slide_num}] ERROR: {e}")

    # 결과 요약
    print()
    print("=" * 60)
    print("추출 완료 요약")
    print("=" * 60)
    print(f"추출된 이미지: {len(extracted)}개")
    print(f"스킵 (크기 미달): {skipped_small}개")
    print(f"스킵 (URL 없음): {skipped_no_url}개")
    print(f"저장 위치: {OUTPUT_DIR}")

    # 슬라이드별 추출 현황
    print()
    print("슬라이드별 추출 현황:")
    slide_counts = {}
    for item in extracted:
        slide_counts[item['slide']] = slide_counts.get(item['slide'], 0) + 1

    for slide_num in range(SLIDE_START, SLIDE_END + 1):
        count = slide_counts.get(slide_num, 0)
        status = "✓" if count > 0 else "✗"
        print(f"  [{slide_num}] {status} {count}개")


if __name__ == '__main__':
    main()
