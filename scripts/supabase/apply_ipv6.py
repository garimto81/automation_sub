# -*- coding: utf-8 -*-
"""
Supabase Migration - IPv6 직접 연결
"""
import os
import sys
import glob
import socket
import psycopg2

# Windows 콘솔 인코딩 설정
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# IPv6 강제 사용
socket.setdefaulttimeout(30)

# Supabase 연결 정보
CONNECTION_STRING = "postgresql://postgres:wlwlvmfhejrtus@[2406:da12:b78:de09:6835:d013:14bb:67a6]:5432/postgres?sslmode=require"

# Migration 파일 경로
MIGRATIONS_DIR = os.path.dirname(os.path.abspath(__file__)) + "/migrations"


def get_migration_files():
    """Migration 파일 목록 (순서대로)"""
    pattern = os.path.join(MIGRATIONS_DIR, "*.sql")
    files = glob.glob(pattern)
    return sorted(files)


def execute_migration(conn, filepath):
    """단일 migration 파일 실행"""
    filename = os.path.basename(filepath)
    print(f"  Running: {filename}")

    with open(filepath, 'r', encoding='utf-8') as f:
        sql_content = f.read()

    with conn.cursor() as cur:
        cur.execute(sql_content)

    conn.commit()
    print(f"  [OK] {filename}")


def main():
    print("=" * 60)
    print("Supabase Migration (IPv6)")
    print("=" * 60)

    # 연결
    print("\n[1] Connecting to Supabase via IPv6...")
    try:
        conn = psycopg2.connect(CONNECTION_STRING)
        print("[OK] Connected!")
    except Exception as e:
        print(f"[FAIL] Connection error: {e}")
        return

    # Migration 파일 목록
    migration_files = get_migration_files()
    print(f"\n[2] Found {len(migration_files)} migration files")

    # 실행
    print("\n[3] Running migrations...")
    success_count = 0
    error_count = 0

    for filepath in migration_files:
        try:
            execute_migration(conn, filepath)
            success_count += 1
        except Exception as e:
            print(f"  [FAIL] {os.path.basename(filepath)}")
            print(f"    Error: {e}")
            error_count += 1
            conn.rollback()

    # 결과
    print("\n" + "=" * 60)
    print(f"Done: {success_count} success, {error_count} failed")
    print("=" * 60)

    # 테이블 목록 확인
    print("\n[4] Checking tables...")
    with conn.cursor() as cur:
        cur.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_type = 'BASE TABLE'
            ORDER BY table_name
        """)
        tables = cur.fetchall()
        print(f"Total {len(tables)} tables:")
        for t in tables:
            print(f"  - {t[0]}")

    conn.close()


if __name__ == "__main__":
    main()
