-- ============================================================
-- Yakut — 007_live_stream_interactions.sql
-- Run this in your Supabase Dashboard SQL Editor
-- ============================================================

-- 1. Create live_stream_messages table
CREATE TABLE IF NOT EXISTS live_stream_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID NOT NULL REFERENCES live_streams(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create live_stream_likes table (supports multiple taps, so no unique constraint required)
CREATE TABLE IF NOT EXISTS live_stream_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID NOT NULL REFERENCES live_streams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create live_stream_blocks table
CREATE TABLE IF NOT EXISTS live_stream_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID NOT NULL REFERENCES live_streams(id) ON DELETE CASCADE,
  blocked_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_by_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_stream_block UNIQUE (stream_id, blocked_user_id)
);

-- 4. Enable RLS
ALTER TABLE live_stream_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_stream_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_stream_blocks ENABLE ROW LEVEL SECURITY;

-- 5. Helper function to check if a user is blocked from a stream
CREATE OR REPLACE FUNCTION is_user_blocked(stream_id UUID, user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM live_stream_blocks
    WHERE stream_id = $1 AND blocked_user_id = $2
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- 6. Add live_streams, live_stream_messages, live_stream_likes, live_stream_blocks to Supabase Realtime publication
DO $$
BEGIN
   ALTER PUBLICATION supabase_realtime ADD TABLE live_streams;
   ALTER PUBLICATION supabase_realtime ADD TABLE live_stream_messages;
   ALTER PUBLICATION supabase_realtime ADD TABLE live_stream_likes;
   ALTER PUBLICATION supabase_realtime ADD TABLE live_stream_blocks;
EXCEPTION WHEN OTHERS THEN
   RAISE NOTICE 'Realtime tables addition handled';
END
$$;

-- 7. RLS Policies for live_stream_messages
CREATE POLICY "messages: read if not blocked"
  ON live_stream_messages FOR SELECT
  USING (NOT is_user_blocked(stream_id, auth.uid()));

CREATE POLICY "messages: insert if authenticated and not blocked"
  ON live_stream_messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id AND
    NOT is_user_blocked(stream_id, auth.uid())
  );

-- 8. RLS Policies for live_stream_likes
CREATE POLICY "likes: anyone can read"
  ON live_stream_likes FOR SELECT
  USING (true);

CREATE POLICY "likes: insert if authenticated and not blocked"
  ON live_stream_likes FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    NOT is_user_blocked(stream_id, auth.uid())
  );

-- 9. RLS Policies for live_stream_blocks
CREATE POLICY "blocks: anyone can read blocks"
  ON live_stream_blocks FOR SELECT
  USING (true);

CREATE POLICY "blocks: stream owner can insert block"
  ON live_stream_blocks FOR INSERT
  WITH CHECK (
    auth.uid() = blocked_by_id AND
    EXISTS (
      SELECT 1 FROM live_streams
      WHERE id = stream_id AND seller_id = auth.uid()
    )
  );

CREATE POLICY "blocks: stream owner can delete block"
  ON live_stream_blocks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM live_streams
      WHERE id = stream_id AND seller_id = auth.uid()
    )
  );

-- 10. Add likes_count column to live_streams table
ALTER TABLE live_streams ADD COLUMN IF NOT EXISTS likes_count INT DEFAULT 0;

-- 11. Trigger function to handle like count updates
CREATE OR REPLACE FUNCTION handle_live_stream_like()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE live_streams SET likes_count = likes_count + 1 WHERE id = NEW.stream_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE live_streams SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.stream_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Create trigger
DROP TRIGGER IF EXISTS on_live_stream_like ON live_stream_likes;
CREATE TRIGGER on_live_stream_like
AFTER INSERT OR DELETE ON live_stream_likes
FOR EACH ROW EXECUTE FUNCTION handle_live_stream_like();
