-- ══════════════════════════════════════════════════════════════
-- Storage RLS for avatars
-- ══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "avatars: public read" ON storage.objects;
CREATE POLICY "avatars: public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars: users upload own prefix" ON storage.objects;
CREATE POLICY "avatars: users upload own prefix"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND split_part(name, '/', 1) = 'avatars'
    AND split_part(name, '/', 2) = auth.uid()::text
  );

DROP POLICY IF EXISTS "avatars: users update own prefix" ON storage.objects;
CREATE POLICY "avatars: users update own prefix"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND split_part(name, '/', 1) = 'avatars'
    AND split_part(name, '/', 2) = auth.uid()::text
  );

DROP POLICY IF EXISTS "avatars: users delete own prefix" ON storage.objects;
CREATE POLICY "avatars: users delete own prefix"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND split_part(name, '/', 1) = 'avatars'
    AND split_part(name, '/', 2) = auth.uid()::text
  );
