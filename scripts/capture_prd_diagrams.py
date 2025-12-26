"""
PRD-0002 다이어그램 이미지 캡처 스크립트
HTML 목업의 #capture-target 요소를 PNG로 캡처
"""

import asyncio
from pathlib import Path
from playwright.async_api import async_playwright

# 프로젝트 루트
PROJECT_ROOT = Path(__file__).parent.parent
MOCKUPS_DIR = PROJECT_ROOT / "docs" / "mockups"
IMAGES_DIR = PROJECT_ROOT / "docs" / "images"

# 캡처할 HTML 파일 목록
DIAGRAMS = [
    "workflow-architecture",
    "automation-domains",
    "ai-agent-hierarchy",
    "data-flow",
    "integration",
    "graphics-automation",
]


async def capture_diagram(page, html_file: Path, output_file: Path):
    """HTML 파일의 #capture-target 요소를 PNG로 캡처"""
    file_url = f"file:///{html_file.as_posix()}"

    await page.goto(file_url)
    await page.wait_for_selector("#capture-target")

    element = page.locator("#capture-target")
    await element.screenshot(path=str(output_file))

    print(f"  Captured: {output_file.name}")


async def main():
    print("PRD-0002 다이어그램 캡처 시작\n")

    # 출력 디렉토리 확인
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()

        for diagram_name in DIAGRAMS:
            html_file = MOCKUPS_DIR / f"{diagram_name}.html"
            output_file = IMAGES_DIR / f"{diagram_name}.png"

            if not html_file.exists():
                print(f"  Skipped: {diagram_name}.html (not found)")
                continue

            await capture_diagram(page, html_file, output_file)

        await browser.close()

    print(f"\n완료: {len(DIAGRAMS)}개 다이어그램 캡처됨")
    print(f"출력 경로: {IMAGES_DIR}")


if __name__ == "__main__":
    asyncio.run(main())
