-- Notification preferences table
-- Stores per-user notification toggles so Edge Functions can check them
-- before sending push notifications.

CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  push_notifications BOOLEAN NOT NULL DEFAULT true,
  live_stream_notifications BOOLEAN NOT NULL DEFAULT true,
  new_followers BOOLEAN NOT NULL DEFAULT true,
  likes_comments BOOLEAN NOT NULL DEFAULT true,
  ratings_reviews BOOLEAN NOT NULL DEFAULT true,
  messages_chat BOOLEAN NOT NULL DEFAULT true,
  in_app_sounds BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- Users can read/write their own preferences
CREATE POLICY "Users can read own preferences"
  ON notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
  ON notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
  ON notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

-- Service role can read any preferences (for Edge Functions)
-- (Service role bypasses RLS by default, so no policy needed)
