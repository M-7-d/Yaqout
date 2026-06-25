CREATE TABLE IF NOT EXISTS chat_mutes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  muted_by_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  muted_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(muted_by_id, muted_user_id)
);

ALTER TABLE chat_mutes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own mutes"
  ON chat_mutes FOR SELECT
  USING (auth.uid() = muted_by_id);

CREATE POLICY "Users can insert own mutes"
  ON chat_mutes FOR INSERT
  WITH CHECK (auth.uid() = muted_by_id);

CREATE POLICY "Users can delete own mutes"
  ON chat_mutes FOR DELETE
  USING (auth.uid() = muted_by_id);
