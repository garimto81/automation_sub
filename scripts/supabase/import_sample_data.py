# -*- coding: utf-8 -*-
"""
4-Schema 샘플 데이터 Import 테스트
- json.*: pokerGFX JSON 데이터
- wsop_plus.*: WSOP+ CSV 데이터
- manual.*: Manual Input 데이터
"""
import sys
import psycopg2
from psycopg2.extras import RealDictCursor
import json

# Windows 콘솔 인코딩
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Supabase Pooler 연결 (Transaction mode)
DB_CONFIG = {
    "host": "aws-1-ap-northeast-2.pooler.supabase.com",
    "port": 6543,
    "database": "postgres",
    "user": "postgres.ohzdaflycmnbxkpvhxcu",
    "password": "wlwlvmfhejrtus",
    "sslmode": "require"
}


def get_connection():
    """DB 연결"""
    return psycopg2.connect(**DB_CONFIG)


def test_manual_schema(cur):
    """manual.* 스키마 샘플 데이터"""
    print("\n" + "=" * 50)
    print("[1] manual.* 스키마 Import")
    print("=" * 50)

    # 1. venues
    print("\n  [1.1] manual.venues...")
    cur.execute("""
        INSERT INTO manual.venues (name, short_name, city, country, country_display, timezone, address, capacity, table_count)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
    """, ("Merit Royal Diamond", "Merit Cyprus", "Kyrenia", "CY", "Cyprus", "Europe/Nicosia",
          "Merit Royal Diamond Hotel & Casino, Kyrenia, Cyprus", 500, 50))
    venue_id = cur.fetchone()["id"]
    print(f"    OK: venue_id = {venue_id}")

    # 2. events
    print("\n  [1.2] manual.events...")
    cur.execute("""
        INSERT INTO manual.events (name, event_code, venue_id, start_date, end_date, status, description)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING id
    """, ("WSOP Super Circuit Cyprus 2026", "WSOP_SC_CYPRUS_2026", venue_id,
          "2026-01-15", "2026-01-28", "upcoming", "WSOP Super Circuit - Cyprus Edition"))
    event_id = cur.fetchone()["id"]
    print(f"    OK: event_id = {event_id}")

    # 3. players_master
    print("\n  [1.3] manual.players_master...")
    players = [
        ("Daniel Negreanu", "Daniel Negreanu", "CA", 6, 50000000),
        ("Phil Ivey", "Phil Ivey", "US", 10, 40000000),
        ("Phil Hellmuth", "Phil Hellmuth", "US", 17, 30000000),
        ("Bryn Kenney", "Bryn Kenney", "US", 1, 60000000),
        ("Justin Bonomo", "Justin Bonomo", "US", 3, 55000000),
        ("Erik Seidel", "Erik Seidel", "US", 9, 40000000),
        ("Fedor Holz", "Fedor Holz", "DE", 2, 35000000),
        ("Jason Koon", "Jason Koon", "US", 1, 45000000),
    ]
    player_ids = []
    for name, display_name, nationality, bracelets, earnings in players:
        cur.execute("""
            INSERT INTO manual.players_master (name, display_name, nationality, wsop_bracelets, total_earnings)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id
        """, (name, display_name, nationality, bracelets, earnings))
        player_ids.append(cur.fetchone()["id"])
    print(f"    OK: {len(player_ids)} players inserted")

    # 4. commentators
    print("\n  [1.4] manual.commentators...")
    cur.execute("""
        INSERT INTO manual.commentators (name, credentials, is_primary)
        VALUES (%s, %s, %s), (%s, %s, %s)
    """, ("Lon McEachern", "WSOP Main Commentator", True,
          "Norman Chad", "WSOP Color Commentator", False))
    print(f"    OK: 2 commentators inserted")

    # 5. feature_tables
    print("\n  [1.5] manual.feature_tables...")
    cur.execute("""
        INSERT INTO manual.feature_tables (table_number, table_name, rfid_device_id, is_active, is_main_feature, max_seats)
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING id
    """, (1, "Main Feature Table", "RFID-001", True, True, 9))
    feature_table_id = cur.fetchone()["id"]
    print(f"    OK: feature_table_id = {feature_table_id}")

    return {
        "venue_id": venue_id,
        "event_id": event_id,
        "player_ids": player_ids,
        "feature_table_id": feature_table_id
    }


def test_wsop_plus_schema(cur, manual_ids):
    """wsop_plus.* 스키마 샘플 데이터"""
    print("\n" + "=" * 50)
    print("[2] wsop_plus.* 스키마 Import")
    print("=" * 50)

    # 1. tournaments
    print("\n  [2.1] wsop_plus.tournaments...")
    cur.execute("""
        INSERT INTO wsop_plus.tournaments
        (name, short_name, tournament_number, tournament_code, buy_in, rake, starting_chips,
         current_level, registered_players, remaining_players, prize_pool, status, event_id, venue_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
    """, ("WSOP Super Circuit Cyprus - Event #1 NLH", "Event #1 NLH", 1, "WSOP_SC_CY_2026_01",
          1100, 100, 50000, 15, 450, 45, 450000, "running",
          manual_ids["event_id"], manual_ids["venue_id"]))
    tournament_id = cur.fetchone()["id"]
    print(f"    OK: tournament_id = {tournament_id}")

    # 2. blind_levels
    print("\n  [2.2] wsop_plus.blind_levels...")
    blind_levels = [
        (tournament_id, 1, 100, 200, 0, 40, False),
        (tournament_id, 2, 100, 200, 200, 40, False),
        (tournament_id, 3, 200, 400, 400, 40, False),
        (tournament_id, 15, 5000, 10000, 10000, 40, True),
    ]
    for t_id, level, sb, bb, ante, duration, is_current in blind_levels:
        cur.execute("""
            INSERT INTO wsop_plus.blind_levels
            (tournament_id, level_number, small_blind, big_blind, ante, duration_minutes, is_current)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (t_id, level, sb, bb, ante, duration, is_current))
    print(f"    OK: {len(blind_levels)} blind levels inserted")

    # 3. payouts
    print("\n  [2.3] wsop_plus.payouts...")
    payouts = [
        (tournament_id, 1, 1, 100000, 22.22, False),
        (tournament_id, 2, 2, 60000, 13.33, False),
        (tournament_id, 3, 3, 40000, 8.89, False),
        (tournament_id, 9, 9, 8000, 1.78, True),  # bubble
    ]
    for t_id, start, end, amount, pct, bubble in payouts:
        cur.execute("""
            INSERT INTO wsop_plus.payouts
            (tournament_id, place_start, place_end, amount, percentage, is_current_bubble)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (t_id, start, end, amount, pct, bubble))
    print(f"    OK: {len(payouts)} payouts inserted")

    # 4. player_instances
    print("\n  [2.4] wsop_plus.player_instances...")
    chips_list = [1500000, 1200000, 980000, 750000, 620000, 480000, 350000, 280000]
    player_names = ["Daniel Negreanu", "Phil Ivey", "Phil Hellmuth", "Bryn Kenney",
                    "Justin Bonomo", "Erik Seidel", "Fedor Holz", "Jason Koon"]
    for i, (player_id, chips, name) in enumerate(zip(manual_ids["player_ids"], chips_list, player_names)):
        cur.execute("""
            INSERT INTO wsop_plus.player_instances
            (tournament_id, player_name, seat_number, chips, current_rank, is_feature_table, player_master_id, feature_table_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (tournament_id, name, i + 1, chips, i + 1, True, player_id, manual_ids["feature_table_id"]))
    print(f"    OK: {len(chips_list)} player instances inserted")

    return {"tournament_id": tournament_id}


def test_json_schema(cur, manual_ids, wsop_plus_ids):
    """json.* 스키마 샘플 데이터 (pokerGFX)"""
    print("\n" + "=" * 50)
    print("[3] json.* 스키마 Import (pokerGFX)")
    print("=" * 50)

    # 1. gfx_sessions
    print("\n  [3.1] json.gfx_sessions...")
    cur.execute("""
        INSERT INTO json.gfx_sessions
        (gfx_id, event_title, table_type, software_version, status, total_hands, tournament_id, feature_table_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
    """, (133811904000000000, "WSOP Super Circuit Cyprus 2026 - Event #1", "FEATURE_TABLE",
          "PokerGFX v3.2.1", "active", 1, wsop_plus_ids["tournament_id"], manual_ids["feature_table_id"]))
    session_id = cur.fetchone()["id"]
    print(f"    OK: session_id = {session_id}")

    # 2. hands
    print("\n  [3.2] json.hands...")
    cur.execute("""
        INSERT INTO json.hands
        (gfx_session_id, hand_number, game_variant, game_class, bet_structure,
         button_seat, small_blind_seat, big_blind_seat, small_blind_amount, big_blind_amount,
         ante_amount, level_number, player_count, is_premium, is_showdown, flop_cards, turn_card, river_card)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
    """, (session_id, 1, "HOLDEM", "FLOP", "NOLIMIT",
          1, 2, 3, 5000, 10000, 10000, 15, 8, True, True,
          json.dumps(["As", "Kh", "Qd"]), "Jc", "Ts"))
    hand_id = cur.fetchone()["id"]
    print(f"    OK: hand_id = {hand_id}")

    # 3. hand_players
    print("\n  [3.3] json.hand_players...")
    hand_players = [
        (hand_id, 1, "Daniel Negreanu", 1500000, 1680000, json.dumps(["Ah", "Kd"]), True, 180000),
        (hand_id, 2, "Phil Ivey", 1200000, 1110000, json.dumps(["Qh", "Qc"]), False, 0),
        (hand_id, 3, "Phil Hellmuth", 980000, 970000, None, False, 0),
    ]
    for h_id, seat, name, start, end, cards, winner, won in hand_players:
        cur.execute("""
            INSERT INTO json.hand_players
            (hand_id, seat_number, player_name, start_stack, end_stack, hole_cards, is_winner, won_amount)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (h_id, seat, name, start, end, cards, winner, won))
    print(f"    OK: {len(hand_players)} hand players inserted")

    # 4. hand_actions
    print("\n  [3.4] json.hand_actions...")
    actions = [
        (hand_id, 1, "preflop", "POST_SB", "post", 2, "Phil Ivey", 5000),
        (hand_id, 2, "preflop", "POST_BB", "post", 3, "Phil Hellmuth", 10000),
        (hand_id, 3, "preflop", "RAISE", "raise", 1, "Daniel Negreanu", 25000),
        (hand_id, 4, "preflop", "CALL", "call", 2, "Phil Ivey", 25000),
        (hand_id, 5, "preflop", "FOLD", "fold", 3, "Phil Hellmuth", None),
        (hand_id, 6, "flop", "BET", "bet", 1, "Daniel Negreanu", 35000),
        (hand_id, 7, "flop", "CALL", "call", 2, "Phil Ivey", 35000),
    ]
    for h_id, order, street, event, action, seat, name, amount in actions:
        cur.execute("""
            INSERT INTO json.hand_actions
            (hand_id, action_order, street, event_type, action, seat_number, player_name, bet_amount)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (h_id, order, street, event, action, seat, name, amount))
    print(f"    OK: {len(actions)} actions inserted")

    # 5. hand_results
    print("\n  [3.5] json.hand_results...")
    results = [
        (hand_id, 1, "Daniel Negreanu", True, 180000, "Broadway Straight", "Straight", 1600),
        (hand_id, 2, "Phil Ivey", False, 0, "Three Queens", "Three of a Kind", 1800),
    ]
    for h_id, seat, name, winner, won, desc, rank, rank_val in results:
        cur.execute("""
            INSERT INTO json.hand_results
            (hand_id, seat_number, player_name, is_winner, won_amount, hand_description, hand_rank, rank_value)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (h_id, seat, name, winner, won, desc, rank, rank_val))
    print(f"    OK: {len(results)} results inserted")

    return {"session_id": session_id, "hand_id": hand_id}


def verify_data(cur):
    """Import 결과 검증"""
    print("\n" + "=" * 50)
    print("[4] Import 결과 검증")
    print("=" * 50)

    schemas_tables = [
        ("manual", ["venues", "events", "players_master", "commentators", "feature_tables"]),
        ("wsop_plus", ["tournaments", "blind_levels", "payouts", "player_instances"]),
        ("json", ["gfx_sessions", "hands", "hand_players", "hand_actions", "hand_results"]),
    ]

    for schema, tables in schemas_tables:
        print(f"\n  [{schema}]")
        for table in tables:
            cur.execute(f"SELECT COUNT(*) as cnt FROM {schema}.{table}")
            count = cur.fetchone()["cnt"]
            print(f"    {table}: {count} rows")


def main():
    print("=" * 60)
    print("4-Schema 샘플 데이터 Import 테스트")
    print("=" * 60)

    conn = None
    try:
        print("\n[0] Connecting to Supabase...")
        conn = get_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        print("    OK: Connected!")

        # 1. Manual 스키마
        manual_ids = test_manual_schema(cur)
        conn.commit()

        # 2. WSOP+ 스키마
        wsop_plus_ids = test_wsop_plus_schema(cur, manual_ids)
        conn.commit()

        # 3. JSON 스키마 (pokerGFX)
        json_ids = test_json_schema(cur, manual_ids, wsop_plus_ids)
        conn.commit()

        # 4. 검증
        verify_data(cur)

        print("\n" + "=" * 60)
        print("Import 완료!")
        print("=" * 60)

    except Exception as e:
        print(f"\n[ERROR] {e}")
        import traceback
        traceback.print_exc()
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    main()
