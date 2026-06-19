import '../entities/live_stream_entity.dart';
import '../entities/live_stream_message_entity.dart';

abstract class StreamRepository {
  Future<LiveStreamEntity> createStream({
    required String sellerId,
    required String title,
    String? productId,
    DateTime? scheduledAt,
  });

  /// Returns a signed Agora token from a Supabase Edge Function.
  Future<String> getAgoraToken(String channelName, int uid, {bool isHost = true});

  Future<void> updateStreamStatus(String streamId, String status);

  /// Host calls this every 30s to signal the stream is still active.
  Future<void> updateHeartbeat(String streamId);

  Future<void> incrementViewerCount(String streamId);
  Future<void> decrementViewerCount(String streamId);

  Stream<List<LiveStreamEntity>> watchLiveStreams();

  Future<List<LiveStreamEntity>> getUpcomingStreams();

  Future<LiveStreamEntity> getStreamById(String id);

  Stream<LiveStreamEntity> watchStreamById(String id);

  Stream<bool> watchUserBlock(String streamId, String userId);

  Future<void> blockUser({
    required String streamId,
    required String blockedUserId,
    required String blockedById,
  });

  Future<void> addLike({
    required String streamId,
    required String userId,
  });

  Future<void> sendMessage({
    required String streamId,
    required String senderId,
    required String content,
  });

  Stream<List<LiveStreamMessageEntity>> watchMessages(String streamId);
}
