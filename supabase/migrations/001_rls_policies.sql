-- ============================================================
-- Yakut — Supabase Row Level Security Policies
-- Run this AFTER the schema SQL from the plan document.
-- ============================================================

-- ── Enable RLS on all tables ────────────────────────────────
ALTER TABLE profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE products     ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews      ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms   ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages     ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories      ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_streams ENABLE ROW LEVEL SECURITY;
ALTER TABLE ads          ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ── Helper: get current user role ───────────────────────────
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ══════════════════════════════════════════════════════════════
-- PROFILES
-- ══════════════════════════════════════════════════════════════
CREATE POLICY "profiles: anyone can read"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "profiles: users update own"
  ON profiles FOR UPDATE USING (id = auth.uid());

CREATE POLICY "profiles: insert own on signup"
  ON profiles FOR INSERT WITH CHECK (id = auth.uid());

-- ══════════════════════════════════════════════════════════════
-- PRODUCTS
-- ══════════════════════════════════════════════════════════════
CREATE POLICY "products: buyers can read active"
  ON products FOR SELECT
  USING (status = 'active' OR seller_id = auth.uid() OR get_my_role() = 'admin');

CREATE POLICY "products: sellers insert own"
  ON products FOR INSERT
  WITH CHECK (seller_id = auth.uid() AND get_my_role() IN ('seller','admin'));

CREATE POLICY "products: sellers update own"
  ON products FOR UPDATE
  USING (seller_id = auth.uid() OR get_my_role() = 'admin');

CREATE POLICY "products: sellers delete own"
  ON products FOR DELETE
  USING (seller_id = auth.uid() OR get_my_role() = 'admin');

-- ══════════════════════════════════════════════════════════════
-- REVIEWS
-- ══════════════════════════════════════════════════════════════
CREATE POLICY "reviews: anyone can read"
  ON reviews FOR SELECT USING (true);

CREATE POLICY "reviews: buyers can insert"
  ON reviews FOR INSERT
  WITH CHECK (reviewer_id = auth.uid() AND get_my_role() = 'buyer');

CREATE POLICY "reviews: reviewer or admin can delete"
  ON reviews FOR DELETE
  USING (reviewer_id = auth.uid() OR get_my_role() = 'admin');

-- ══════════════════════════════════════════════════════════════
-- CHAT ROOMS
-- ══════════════════════════════════════════════════════════════
CREATE POLICY "chat_rooms: participants can read"
  ON chat_rooms FOR SELECT
  USING (buyer_id = auth.uid() OR seller_id = auth.uid());

CREATE POLICY "chat_rooms: buyers can create"
  ON chat_rooms FOR INSERT
  WITH CHECK (buyer_id = auth.uid());

-- ══════════════════════════════════════════════════════════════
-- MESSAGES
-- ══════════════════════════════════════════════════════════════
CREATE POLICY "messages: room participants can read"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id = messages.room_id
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
  );

CREATE POLICY "messages: participants can insert"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id = messages.room_id
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
  );

CREATE POLICY "messages: participants can update (mark read)"
  ON messages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id = messages.room_id
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
  );

-- ══════════════════════════════════════════════════════════════
-- STORIES
-- ══════════════════════════════════════════════════════════════
CREATE POLICY "stories: anyone can read non-expired"
  ON stories FOR SELECT
  USING (expires_at > NOW());

CREATE POLICY "stories: sellers insert own"
  ON stories FOR INSERT
  WITH CHECK (seller_id = auth.uid() AND get_my_role() = 'seller');

CREATE POLICY "stories: sellers delete own"
  ON stories FOR DELETE
  USING (seller_id = auth.uid() OR get_my_role() = 'admin');

-- ══════════════════════════════════════════════════════════════
-- LIVE STREAMS
-- ══════════════════════════════════════════════════════════════
CREATE POLICY "live_streams: anyone can read"
  ON live_streams FOR SELECT USING (true);

CREATE POLICY "live_streams: sellers insert own"
  ON live_streams FOR INSERT
  WITH CHECK (seller_id = auth.uid() AND get_my_role() IN ('seller','admin'));

CREATE POLICY "live_streams: sellers update own"
  ON live_streams FOR UPDATE
  USING (seller_id = auth.uid() OR get_my_role() = 'admin');

-- ══════════════════════════════════════════════════════════════
-- ADS
-- ══════════════════════════════════════════════════════════════
CREATE POLICY "ads: anyone can read active"
  ON ads FOR SELECT
  USING (status = 'active' OR seller_id = auth.uid() OR get_my_role() = 'admin');

CREATE POLICY "ads: sellers insert own"
  ON ads FOR INSERT
  WITH CHECK (seller_id = auth.uid());

-- ══════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ══════════════════════════════════════════════════════════════
CREATE POLICY "notifications: user reads own"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "notifications: user updates own (mark read)"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

-- ══════════════════════════════════════════════════════════════
-- STORAGE BUCKET POLICIES
-- ══════════════════════════════════════════════════════════════
-- Run these in Supabase Dashboard → Storage → Policies

-- product-images bucket: public read, authenticated write
INSERT INTO storage.buckets (id, name, public) VALUES ('product-images', 'product-images', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('chat-media', 'chat-media', false) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('stories', 'stories', true) ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS (called by StreamRepository)
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION increment_viewer_count(stream_id UUID)
RETURNS VOID AS $$
  UPDATE live_streams SET viewer_count = viewer_count + 1 WHERE id = stream_id;
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_viewer_count(stream_id UUID)
RETURNS VOID AS $$
  UPDATE live_streams
  SET viewer_count = GREATEST(viewer_count - 1, 0)
  WHERE id = stream_id;
$$ LANGUAGE sql SECURITY DEFINER;
