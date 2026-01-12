-- ============================================================
-- Migration: 052_enable_realtime.sql
-- Description: Supabase 통합 스키마 - Realtime 활성화
-- Author: Claude Code
-- Date: 2026-01-08
-- Phase: 6 - RLS & Realtime
-- ============================================================

-- ============================================================
-- Supabase Realtime 활성화
-- supabase_realtime publication에 테이블 추가
-- ============================================================

-- P0: 필수 실시간 테이블
ALTER PUBLICATION supabase_realtime ADD TABLE hands;
ALTER PUBLICATION supabase_realtime ADD TABLE player_instances;
ALTER PUBLICATION supabase_realtime ADD TABLE graphics_queue;
ALTER PUBLICATION supabase_realtime ADD TABLE blind_levels;

-- P1: 권장 실시간 테이블
ALTER PUBLICATION supabase_realtime ADD TABLE chip_flow;
ALTER PUBLICATION supabase_realtime ADD TABLE eliminations;
ALTER PUBLICATION supabase_realtime ADD TABLE feature_tables;

-- Comment
COMMENT ON TABLE hands IS 'Realtime 활성화됨 - 핸드 시작/완료 이벤트';
COMMENT ON TABLE player_instances IS 'Realtime 활성화됨 - 칩/순위 변동';
COMMENT ON TABLE graphics_queue IS 'Realtime 활성화됨 - 자막 트리거';
COMMENT ON TABLE blind_levels IS 'Realtime 활성화됨 - 레벨 업';
COMMENT ON TABLE chip_flow IS 'Realtime 활성화됨 - 칩 플로우 업데이트';
COMMENT ON TABLE eliminations IS 'Realtime 활성화됨 - 탈락 이벤트';
COMMENT ON TABLE feature_tables IS 'Realtime 활성화됨 - 피처 테이블 활성화';

-- ============================================================
-- Realtime 구독 예시 (클라이언트 코드)
-- ============================================================
--
-- // hands 테이블 구독
-- const handsSubscription = supabase
--   .channel('hands-changes')
--   .on('postgres_changes', {
--     event: '*',
--     schema: 'public',
--     table: 'hands'
--   }, (payload) => {
--     console.log('Hand change:', payload);
--   })
--   .subscribe();
--
-- // player_instances 칩 변동 구독
-- const chipsSubscription = supabase
--   .channel('chips-changes')
--   .on('postgres_changes', {
--     event: 'UPDATE',
--     schema: 'public',
--     table: 'player_instances',
--     filter: `tournament_id=eq.${tournamentId}`
--   }, (payload) => {
--     console.log('Chips changed:', payload);
--   })
--   .subscribe();
--
-- // graphics_queue 대기 자막 구독
-- const queueSubscription = supabase
--   .channel('queue-changes')
--   .on('postgres_changes', {
--     event: 'INSERT',
--     schema: 'public',
--     table: 'graphics_queue',
--     filter: `status=eq.pending`
--   }, (payload) => {
--     console.log('New graphic:', payload);
--   })
--   .subscribe();
-- ============================================================
