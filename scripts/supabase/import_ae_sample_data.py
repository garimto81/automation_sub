# -*- coding: utf-8 -*-
"""
ae.* 스키마 샘플 데이터 Import
- templates, compositions, composition_layers
- data_types, layer_data_mappings
- render_jobs, render_outputs
"""
import sys
import psycopg2
from psycopg2.extras import RealDictCursor
import json

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

DB_CONFIG = {
    "host": "aws-1-ap-northeast-2.pooler.supabase.com",
    "port": 6543,
    "database": "postgres",
    "user": "postgres.ohzdaflycmnbxkpvhxcu",
    "password": "wlwlvmfhejrtus",
    "sslmode": "require"
}


def main():
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor(cursor_factory=RealDictCursor)

    print("=" * 60)
    print("ae.* 스키마 샘플 데이터 Import")
    print("=" * 60)

    try:
        # 1. templates
        print("\n[1] ae.templates...")
        cur.execute("""
            INSERT INTO ae.templates
            (name, file_path, file_size, aep_version, composition_count, text_layer_count, description, tags, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, ("WSOP_Cyprus_2026_Main.aep", "D:/AE Projects/WSOP/WSOP_Cyprus_2026_Main.aep",
              125000000, "24.0", 58, 1397, "WSOP Cyprus 2026 Main Graphics Template",
              json.dumps(["WSOP", "Cyprus", "2026", "Broadcast"]), True))
        template_id = cur.fetchone()["id"]
        print(f"    OK: template_id = {template_id}")

        # 2. compositions
        print("\n[2] ae.compositions...")
        compositions = [
            ("Feature Table Leaderboard MAIN", "leaderboard", 1920, 1080, 29.97, 300, 42, 8, 0),
            ("Mini Chip Counts MAIN", "chip_count", 1920, 1080, 29.97, 150, 21, 0, 0),
            ("Payouts", "payout", 1920, 1080, 29.97, 200, 31, 0, 0),
            ("Player Profile", "player_profile", 1920, 1080, 29.97, 180, 12, 2, 0),
            ("Commentator Profile", "commentator", 1920, 1080, 29.97, 150, 8, 2, 0),
            ("Blind Level", "blind_level", 1920, 1080, 29.97, 120, 12, 0, 0),
            ("Event Info", "event_info", 1920, 1080, 29.97, 100, 10, 1, 0),
            ("Elimination Banner", "elimination", 1920, 1080, 29.97, 90, 2, 1, 0),
        ]
        comp_ids = []
        for name, comp_type, w, h, fps, dur, text_cnt, img_cnt, vid_cnt in compositions:
            cur.execute("""
                INSERT INTO ae.compositions
                (template_id, name, comp_type, width, height, frame_rate, duration_frames,
                 text_layer_count, image_layer_count, video_layer_count, is_renderable)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (template_id, name, comp_type, w, h, fps, dur, text_cnt, img_cnt, vid_cnt, True))
            comp_ids.append(cur.fetchone()["id"])
        print(f"    OK: {len(comp_ids)} compositions inserted")

        # 3. composition_layers (Feature Table Leaderboard용)
        print("\n[3] ae.composition_layers...")
        leaderboard_comp_id = comp_ids[0]
        layers = [
            ("var_Name 1", "text", 1, True, "var_", "player_name", 1, "Player 1"),
            ("var_Name 2", "text", 2, True, "var_", "player_name", 2, "Player 2"),
            ("var_Name 3", "text", 3, True, "var_", "player_name", 3, "Player 3"),
            ("var_Chips 1", "text", 4, True, "var_", "chips", 1, "1,000,000"),
            ("var_Chips 2", "text", 5, True, "var_", "chips", 2, "800,000"),
            ("var_Chips 3", "text", 6, True, "var_", "chips", 3, "600,000"),
            ("var_BBs 1", "text", 7, True, "var_", "bb_count", 1, "100"),
            ("var_BBs 2", "text", 8, True, "var_", "bb_count", 2, "80"),
            ("var_BBs 3", "text", 9, True, "var_", "bb_count", 3, "60"),
            ("img_Flag 1", "image", 10, True, "img_", "flag", 1, "flags/us.png"),
            ("img_Flag 2", "image", 11, True, "img_", "flag", 2, "flags/ca.png"),
            ("img_Flag 3", "image", 12, True, "img_", "flag", 3, "flags/de.png"),
        ]
        layer_ids = []
        for layer_name, layer_type, idx, is_dynamic, prefix, field, slot, default in layers:
            cur.execute("""
                INSERT INTO ae.composition_layers
                (composition_id, layer_name, layer_type, layer_index, is_dynamic, dynamic_prefix, data_field, slot_index, default_value)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (leaderboard_comp_id, layer_name, layer_type, idx, is_dynamic, prefix, field, slot, default))
            layer_ids.append(cur.fetchone()["id"])
        print(f"    OK: {len(layer_ids)} layers inserted")

        # 4. data_types
        print("\n[4] ae.data_types...")
        data_types = [
            ("leaderboard_data", "broadcast", "Leaderboard Data", "Feature table leaderboard with player chips and rankings", "wsop_plus", "player_instances"),
            ("player_profile_data", "player", "Player Profile Data", "Player biography and statistics", "manual", "players_master"),
            ("blind_level_data", "tournament", "Blind Level Data", "Current blind level information", "wsop_plus", "blind_levels"),
            ("payout_data", "tournament", "Payout Data", "Prize payout structure", "wsop_plus", "payouts"),
        ]
        type_ids = []
        for type_name, category, display, desc, src_schema, src_table in data_types:
            cur.execute("""
                INSERT INTO ae.data_types
                (type_name, category, display_name, description, schema_definition, source_schema, source_table, is_active)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (type_name, category, display, desc, json.dumps({"type": "object"}), src_schema, src_table, True))
            type_ids.append(cur.fetchone()["id"])
        print(f"    OK: {len(type_ids)} data types inserted")

        # 5. layer_data_mappings
        print("\n[5] ae.layer_data_mappings...")
        mappings = [
            (layer_ids[0], type_ids[0], "wsop_plus", "player_instances", "player_name", None, None),
            (layer_ids[3], type_ids[0], "wsop_plus", "player_instances", "chips", "format_number", json.dumps({"separator": ","})),
            (layer_ids[6], type_ids[0], "wsop_plus", "player_instances", "bb_count", "round", json.dumps({"decimals": 0})),
            (layer_ids[9], type_ids[0], "manual", "players_master", "nationality", "flag_path", json.dumps({"prefix": "flags/", "suffix": ".png"})),
        ]
        for layer_id, type_id, src_schema, src_table, src_col, transform, config in mappings:
            cur.execute("""
                INSERT INTO ae.layer_data_mappings
                (layer_id, data_type_id, source_schema, source_table, source_column, transform_type, transform_config)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (layer_id, type_id, src_schema, src_table, src_col, transform, config))
        print(f"    OK: {len(mappings)} mappings inserted")

        # 6. render_jobs
        print("\n[6] ae.render_jobs...")
        cur.execute("""
            INSERT INTO ae.render_jobs
            (composition_id, data_type_id, job_uid, data_payload, slot_data, priority, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (leaderboard_comp_id, type_ids[0], "JOB-2026-001",
              json.dumps({"event_name": "WSOP Cyprus 2026", "level": 15}),
              json.dumps([
                  {"name": "Daniel Negreanu", "chips": 1500000, "bb": 150},
                  {"name": "Phil Ivey", "chips": 1200000, "bb": 120},
                  {"name": "Phil Hellmuth", "chips": 980000, "bb": 98}
              ]),
              8, "completed"))
        job_id = cur.fetchone()["id"]
        print(f"    OK: job_id = {job_id}")

        # 7. render_outputs
        print("\n[7] ae.render_outputs...")
        cur.execute("""
            INSERT INTO ae.render_outputs
            (render_job_id, output_type, file_path, file_name, file_size, mime_type, width, height, duration_seconds, codec)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (job_id, "video", "D:/Renders/leaderboard_001.mp4", "leaderboard_001.mp4",
              15000000, "video/mp4", 1920, 1080, 10.0, "h264"))
        print("    OK: 1 output inserted")

        conn.commit()

        # 검증
        print("\n" + "=" * 60)
        print("ae.* 스키마 검증")
        print("=" * 60)
        tables = ["templates", "compositions", "composition_layers", "data_types", "layer_data_mappings", "render_jobs", "render_outputs"]
        for table in tables:
            cur.execute(f"SELECT COUNT(*) as cnt FROM ae.{table}")
            count = cur.fetchone()["cnt"]
            print(f"  {table}: {count} rows")

        print("\n" + "=" * 60)
        print("Import 완료!")
        print("=" * 60)

    except Exception as e:
        print(f"\n[ERROR] {e}")
        import traceback
        traceback.print_exc()
        conn.rollback()
    finally:
        conn.close()


if __name__ == "__main__":
    main()
