"""Migration 파일 합치기"""
import os
import glob

MIGRATIONS_DIR = os.path.dirname(os.path.abspath(__file__)) + "/migrations"
OUTPUT_FILE = os.path.dirname(os.path.abspath(__file__)) + "/all_migrations.sql"

# Migration 파일 목록 (순서대로)
files = sorted(glob.glob(os.path.join(MIGRATIONS_DIR, "*.sql")))

with open(OUTPUT_FILE, 'w', encoding='utf-8') as out:
    out.write("-- ============================================================\n")
    out.write("-- Supabase 통합 DB 스키마 - ALL MIGRATIONS\n")
    out.write("-- Generated from 28 migration files\n")
    out.write("-- ============================================================\n\n")

    for filepath in files:
        filename = os.path.basename(filepath)
        if filename.startswith('050_') or filename.startswith('051_') or filename.startswith('052_'):
            continue  # RLS/Realtime은 별도 실행

        out.write(f"\n-- ============================================================\n")
        out.write(f"-- FILE: {filename}\n")
        out.write(f"-- ============================================================\n\n")

        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            out.write(content)
            out.write("\n\n")

print(f"Generated: {OUTPUT_FILE}")
print(f"Total files: {len(files)}")
