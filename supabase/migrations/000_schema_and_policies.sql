-- ══════════════════════════════════════════════════════════════
-- 1. TABLES SCHEMA
-- ══════════════════════════════════════════════════════════════

-- profiles (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('buyer','seller','admin')),
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- categories
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  icon_url TEXT,
  parent_id UUID REFERENCES categories(id)
);

-- products
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES profiles(id),
  category_id UUID REFERENCES categories(id),
  title TEXT NOT NULL,
  description TEXT,
  price NUMERIC(12,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  stock INT DEFAULT 0,
  is_featured BOOLEAN DEFAULT FALSE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active','draft','sold','banned')),
  images TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- reviews
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES profiles(id),
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- chat_rooms
CREATE TABLE chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES profiles(id),
  seller_id UUID NOT NULL REFERENCES profiles(id),
  product_id UUID REFERENCES products(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- messages
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id),
  content TEXT,
  media_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- stories
CREATE TABLE stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES profiles(id),
  media_url TEXT NOT NULL,
  caption TEXT,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- live_streams
CREATE TABLE live_streams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES profiles(id),
  product_id UUID REFERENCES products(id),
  agora_channel TEXT NOT NULL,
  title TEXT,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled','live','ended')),
  scheduled_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  viewer_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ads (featured ads)
CREATE TABLE ads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES profiles(id),
  product_id UUID REFERENCES products(id),
  type TEXT CHECK (type IN ('banner','featured','story_boost')),
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  payment_ref TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','active','expired')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  title TEXT,
  body TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════
-- 2. ENABLE ROW LEVEL SECURITY
-- ══════════════════════════════════════════════════════════════
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
-- 3. RLS POLICIES
-- ══════════════════════════════════════════════════════════════

-- Profiles
CREATE POLICY "profiles: anyone can read"
  ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles: users update own"
  ON profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "profiles: insert own on signup"
  ON profiles FOR INSERT WITH CHECK (id = auth.uid());

-- Products
CREATE POLICY "products: buyers can read active"
  ON products FOR SELECT USING (status = 'active' OR seller_id = auth.uid() OR get_my_role() = 'admin');
CREATE POLICY "products: sellers insert own"
  ON products FOR INSERT WITH CHECK (seller_id = auth.uid() AND get_my_role() IN ('seller','admin'));
CREATE POLICY "products: sellers update own"
  ON products FOR UPDATE USING (seller_id = auth.uid() OR get_my_role() = 'admin');
CREATE POLICY "products: sellers delete own"
  ON products FOR DELETE USING (seller_id = auth.uid() OR get_my_role() = 'admin');

-- Reviews
CREATE POLICY "reviews: anyone can read"
  ON reviews FOR SELECT USING (true);
CREATE POLICY "reviews: buyers can insert"
  ON reviews FOR INSERT WITH CHECK (reviewer_id = auth.uid() AND get_my_role() = 'buyer');
CREATE POLICY "reviews: reviewer or admin can delete"
  ON reviews FOR DELETE USING (reviewer_id = auth.uid() OR get_my_role() = 'admin');

-- Chat Rooms
CREATE POLICY "chat_rooms: participants can read"
  ON chat_rooms FOR SELECT USING (buyer_id = auth.uid() OR seller_id = auth.uid());
CREATE POLICY "chat_rooms: buyers can create"
  ON chat_rooms FOR INSERT WITH CHECK (buyer_id = auth.uid());

-- Messages
CREATE POLICY "messages: room participants can read"
  ON messages FOR SELECT USING (
    EXISTS (SELECT 1 FROM chat_rooms WHERE id = messages.room_id AND (buyer_id = auth.uid() OR seller_id = auth.uid()))
  );
CREATE POLICY "messages: participants can insert"
  ON messages FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND EXISTS (SELECT 1 FROM chat_rooms WHERE id = messages.room_id AND (buyer_id = auth.uid() OR seller_id = auth.uid()))
  );
CREATE POLICY "messages: participants can update (mark read)"
  ON messages FOR UPDATE USING (
    EXISTS (SELECT 1 FROM chat_rooms WHERE id = messages.room_id AND (buyer_id = auth.uid() OR seller_id = auth.uid()))
  );

-- Stories
CREATE POLICY "stories: anyone can read non-expired"
  ON stories FOR SELECT USING (expires_at > NOW());
CREATE POLICY "stories: sellers insert own"
  ON stories FOR INSERT WITH CHECK (seller_id = auth.uid() AND get_my_role() = 'seller');
CREATE POLICY "stories: sellers delete own"
  ON stories FOR DELETE USING (seller_id = auth.uid() OR get_my_role() = 'admin');

-- Live Streams
CREATE POLICY "live_streams: anyone can read"
  ON live_streams FOR SELECT USING (true);
CREATE POLICY "live_streams: sellers insert own"
  ON live_streams FOR INSERT WITH CHECK (seller_id = auth.uid() AND get_my_role() IN ('seller','admin'));
CREATE POLICY "live_streams: sellers update own"
  ON live_streams FOR UPDATE USING (seller_id = auth.uid() OR get_my_role() = 'admin');

-- Ads
CREATE POLICY "ads: anyone can read active"
  ON ads FOR SELECT USING (status = 'active' OR seller_id = auth.uid() OR get_my_role() = 'admin');
CREATE POLICY "ads: sellers insert own"
  ON ads FOR INSERT WITH CHECK (seller_id = auth.uid());

-- Notifications
CREATE POLICY "notifications: user reads own"
  ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notifications: user updates own (mark read)"
  ON notifications FOR UPDATE USING (user_id = auth.uid());

-- ══════════════════════════════════════════════════════════════
-- 4. STORAGE BUCKET POLICIES
-- ══════════════════════════════════════════════════════════════
INSERT INTO storage.buckets (id, name, public) VALUES ('product-images', 'product-images', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('chat-media', 'chat-media', false) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('stories', 'stories', true) ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- 5. HELPER FUNCTIONS
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
