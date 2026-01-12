# -*- coding: utf-8 -*-
"""
Supabase Migration - REST API 방식
"""
import os
import sys
import glob
import requests

# Windows 콘솔 인코딩 설정
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Supabase 프로젝트 정보
PROJECT_REF = "feqpwuretyyejwrzcpum"
SUPABASE_URL = f"https://{PROJECT_REF}.supabase.co"
SERVICE_KEY = "sb_secret_fpHJ8Gjc_Hdfg046h4NsTA_KEWk26sD"

# Phase별 SQL 파일 경로
PHASE_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_FILES = [
    "phase1_core_reference.sql",
    "phase2_player_system.sql",
    "phase3_hand_system.sql",
    "phase4_broadcast_system.sql",
    "phase5_views_functions.sql",
    "phase6_rls_realtime.sql",
]


def execute_sql_via_rpc(sql_content):
    """Supabase RPC를 통해 SQL 실행 (불가능)"""
    # Supabase REST API는 직접 SQL 실행을 지원하지 않음
    # Management API 사용 필요
    pass


def execute_sql_via_management_api(sql_content):
    """Supabase Management API를 통해 SQL 실행"""
    # Management API 엔드포인트
    url = f"https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query"

    headers = {
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json"
    }

    data = {
        "query": sql_content
    }

    response = requests.post(url, headers=headers, json=data)
    return response


def main():
    print("=" * 60)
    print("Supabase Migration via API")
    print("=" * 60)

    # Management API 테스트
    print("\n[1] Testing Supabase API...")

    test_url = f"https://api.supabase.com/v1/projects/{PROJECT_REF}"
    headers = {
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.get(test_url, headers=headers, timeout=30)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("[OK] API connected!")
            print(response.json())
        else:
            print(f"[FAIL] {response.text}")
    except Exception as e:
        print(f"[FAIL] {e}")


if __name__ == "__main__":
    main()
