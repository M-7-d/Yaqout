import '../../domain/entities/live_stream_message_entity.dart';

class LiveStreamMessageModel extends LiveStreamMessageEntity {
  const LiveStreamMessageModel({
    required super.id,
    required super.streamId,
    required super.senderId,
    required super.content,
    required super.createdAt,
    super.senderName,
    super.senderAvatar,
  });

  factory LiveStreamMessageModel.fromJson(Map<String, dynamic> j) {
    final profile = j['profiles'] as Map<String, dynamic>?;
    return LiveStreamMessageModel(
      id:           j['id'] as String,
      streamId:     j['stream_id'] as String,
      senderId:     j['sender_id'] as String,
      content:      j['content'] as String,
      createdAt:    DateTime.parse(j['created_at'] as String),
      senderName:    profile?['full_name'] as String?,
      senderAvatar:  profile?['avatar_url'] as String?,
    );
  }

  factory LiveStreamMessageModel.fromRawJson(Map<String, dynamic> j) {
    return LiveStreamMessageModel(
      id:           j['id'] as String,
      streamId:     j['stream_id'] as String,
      senderId:     j['sender_id'] as String,
      content:      j['content'] as String,
      createdAt:    DateTime.parse(j['created_at'] as String),
    );
  }

  LiveStreamMessageEntity toEntity() => LiveStreamMessageEntity(
        id:           id,
        streamId:     streamId,
        senderId:     senderId,
        content:      content,
        createdAt:    createdAt,
        senderName:   senderName,
        senderAvatar: senderAvatar,
      );
}
