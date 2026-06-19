-- ============================================================
-- Yakut — 008_live_stream_heartbeat.sql
-- Adds a heartbeat mechanism to auto-end stale live streams
-- when the host's app is killed without graceful cleanup.
-- Run this in your Supabase Dashboard SQL Editor.
-- ============================================================

-- 1. Add last_heartbeat_at column to live_streams
ALTER TABLE live_streams
  ADD COLUMN IF NOT EXISTS last_heartbeat_at TIMESTAMPTZ;

-- 2. RPC function: host calls this every 30s while streaming
CREATE OR REPLACE FUNCTION update_stream_heartbeat(p_stream_id UUID)
RETURNS VOID AS $$
  UPDATE live_streams
  SET last_heartbeat_at = NOW()
  WHERE id = p_stream_id
    AND seller_id = auth.uid()
    AND status = 'live';
$$ LANGUAGE sql SECURITY DEFINER;

-- 3. Function to clean up stale streams (no heartbeat for 60s)
--    This is called by pg_cron or by the Edge Function.
CREATE OR REPLACE FUNCTION cleanup_stale_live_streams()
RETURNS INT AS $$
DECLARE
  affected INT;
BEGIN
  UPDATE live_streams
  SET status = 'ended',
      ended_at = NOW()
  WHERE status = 'live'
    AND last_heartbeat_at IS NOT NULL
    AND last_heartbeat_at < NOW() - INTERVAL '60 seconds';

  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. (Optional) If you have pg_cron enabled, uncomment the line below
--    to auto-run cleanup every minute:
--
-- SELECT cron.schedule(
--   'cleanup-stale-streams',
--   '* * * * *',
--   $$ SELECT cleanup_stale_live_streams(); $$
-- );
