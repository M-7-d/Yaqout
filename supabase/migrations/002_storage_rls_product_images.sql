-- ══════════════════════════════════════════════════════════════
-- Storage RLS for product-images (and chat-media)
-- Buckets are created in 000/001, but without policies on
-- storage.objects every upload returns 403 / "new row violates RLS".
-- ══════════════════════════════════════════════════════════════

-- product-images: object paths are products/{seller_id}/{filename}
DROP POLICY IF EXISTS "product-images: public read" ON storage.objects;
CREATE POLICY "product-images: public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "product-images: sellers upload own prefix" ON storage.objects;
CREATE POLICY "product-images: sellers upload own prefix"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'product-images'
    AND split_part(name, '/', 1) = 'products'
    AND split_part(name, '/', 2) = auth.uid()::text
  );

DROP POLICY IF EXISTS "product-images: sellers update own prefix" ON storage.objects;
CREATE POLICY "product-images: sellers update own prefix"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'product-images'
    AND split_part(name, '/', 1) = 'products'
    AND split_part(name, '/', 2) = auth.uid()::text
  );

DROP POLICY IF EXISTS "product-images: sellers delete own prefix" ON storage.objects;
CREATE POLICY "product-images: sellers delete own prefix"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'product-images'
    AND split_part(name, '/', 1) = 'products'
    AND split_part(name, '/', 2) = auth.uid()::text
  );

-- chat-media: paths are {roomId}/{filename} (see ChatRepositoryImpl)
DROP POLICY IF EXISTS "chat-media: participants read" ON storage.objects;
CREATE POLICY "chat-media: participants read"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'chat-media'
    AND EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id::text = split_part(name, '/', 1)
        AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "chat-media: participants insert" ON storage.objects;
CREATE POLICY "chat-media: participants insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'chat-media'
    AND EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id::text = split_part(name, '/', 1)
        AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
  );
