"""
Google Slides 이미지 크기 분석 스크립트

각 슬라이드의 이미지 크기를 분석하여
자막 이미지 vs 슬라이드 캡처 구분 기준 도출
"""
import os
from pathlib import Path
from typing import Dict, Optional
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

# Google API 스코프
SCOPES = [
    'https://www.googleapis.com/auth/presentations.readonly',
]


def get_credentials() -> Optional[Credentials]:
    """Google API 인증 정보 가져오기"""
    creds_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS') or \
                 os.environ.get('GOOGLE_SHEETS_CREDENTIALS')

    if creds_path and Path(creds_path).exists():
        return Credentials.from_service_account_file(creds_path, scopes=SCOPES)

    default_paths = [
        Path('D:/AI/claude01/json/service_account_key.json'),
        Path.home() / '.config' / 'gcloud' / 'application_default_credentials.json',
    ]

    for path in default_paths:
        if path.exists():
            return Credentials.from_service_account_file(str(path), scopes=SCOPES)

    print("ERROR: Google API 인증 파일을 찾을 수 없습니다.")
    return None


def analyze_presentation(service, presentation_id: str, name: str) -> Dict:
    """프레젠테이션의 이미지 크기 분석"""

    presentation = service.presentations().get(
        presentationId=presentation_id
    ).execute()

    # 슬라이드 크기 (EMU 단위)
    page_size = presentation.get('pageSize', {})
    slide_width = page_size.get('width', {}).get('magnitude', 0)
    slide_height = page_size.get('height', {}).get('magnitude', 0)

    print(f"\n{'='*60}")
    print(f"프레젠테이션: {name}")
    print(f"{'='*60}")
    print(f"슬라이드 크기: {slide_width:.0f} x {slide_height:.0f} EMU")
    print(f"슬라이드 크기: {slide_width/914400:.2f} x {slide_height/914400:.2f} 인치")

    slides = presentation.get('slides', [])

    all_images = []

    for slide_idx, slide in enumerate(slides, 1):
        slide_images = []
        for element in slide.get('pageElements', []):
            image = element.get('image')
            if not image:
                continue

            # 이미지 크기 가져오기
            size = element.get('size', {})
            width = size.get('width', {}).get('magnitude', 0)
            height = size.get('height', {}).get('magnitude', 0)

            # 이미지 위치
            transform = element.get('transform', {})
            translate_x = transform.get('translateX', 0)
            translate_y = transform.get('translateY', 0)

            # contentUrl 존재 여부
            content_url = image.get('contentUrl', '')
            source_url = image.get('sourceUrl', '')

            # 슬라이드 대비 비율 계산
            width_ratio = (width / slide_width * 100) if slide_width > 0 else 0
            height_ratio = (height / slide_height * 100) if slide_height > 0 else 0

            slide_images.append({
                'slide': slide_idx,
                'width': width,
                'height': height,
                'width_ratio': width_ratio,
                'height_ratio': height_ratio,
                'pos_x': translate_x,
                'pos_y': translate_y,
                'has_content_url': bool(content_url),
                'has_source_url': bool(source_url),
            })

        # 슬라이드당 이미지 수 출력 (여러 개면 상세 출력)
        if len(slide_images) > 1:
            print(f"\n슬라이드 {slide_idx}: {len(slide_images)}개 이미지")
            for i, img in enumerate(slide_images):
                print(f"  [{i+1}] 크기: {img['width_ratio']:.1f}% x {img['height_ratio']:.1f}%")
                print(f"      위치: ({img['pos_x']:.0f}, {img['pos_y']:.0f})")

        all_images.extend(slide_images)

    # 이미지 크기별 분류
    large_images = [img for img in all_images if img['width_ratio'] > 80 and img['height_ratio'] > 80]
    medium_images = [img for img in all_images if 50 < img['width_ratio'] <= 80 or 50 < img['height_ratio'] <= 80]
    small_images = [img for img in all_images if img['width_ratio'] <= 50 and img['height_ratio'] <= 50]

    print(f"\n총 이미지: {len(all_images)}개")
    print(f"  - Large (>80%): {len(large_images)}개 (슬라이드 캡처 추정)")
    print(f"  - Medium (50-80%): {len(medium_images)}개")
    print(f"  - Small (<50%): {len(small_images)}개 (자막 이미지 추정)")

    # 크기 분포 출력
    print(f"\n크기 분포:")
    print(f"{'Slide':<8} {'Width%':<10} {'Height%':<10} {'Type':<15}")
    print("-" * 45)

    for img in sorted(all_images, key=lambda x: x['width_ratio'], reverse=True)[:20]:
        img_type = "LARGE (캡처?)" if img['width_ratio'] > 80 else "SMALL (자막?)"
        print(f"{img['slide']:<8} {img['width_ratio']:<10.1f} {img['height_ratio']:<10.1f} {img_type:<15}")

    if len(all_images) > 20:
        print(f"... 외 {len(all_images) - 20}개")

    return {
        'slide_width': slide_width,
        'slide_height': slide_height,
        'total_images': len(all_images),
        'large': len(large_images),
        'medium': len(medium_images),
        'small': len(small_images),
    }


def main():
    """메인 함수"""
    print("Google Slides 이미지 크기 분석...")

    creds = get_credentials()
    if not creds:
        return

    service = build('slides', 'v1', credentials=creds)

    results = {}
    for key, pres in PRESENTATIONS.items():
        try:
            results[key] = analyze_presentation(
                service,
                pres['id'],
                pres['name']
            )
        except Exception as e:
            print(f"ERROR ({pres['name']}): {e}")

    # 권장 임계값 출력
    print(f"\n{'='*60}")
    print("권장 필터 설정")
    print("="*60)
    print("슬라이드 크기 80% 이상 = 슬라이드 캡처 (제외)")
    print("슬라이드 크기 80% 미만 = 자막 이미지 (포함)")


if __name__ == '__main__':
    main()
