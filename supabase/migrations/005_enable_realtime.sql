-- Enable Realtime for chat functionality
BEGIN;
  -- Add messages and chat_rooms tables to the supabase_realtime publication
  ALTER PUBLICATION supabase_realtime ADD TABLE messages;
  ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;
COMMIT;
