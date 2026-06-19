// Live Stream Chat Message Entity
class LiveStreamMessageEntity {
  final String id;
  final String streamId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  // Joined profile fields (optional)
  final String? senderName;
  final String? senderAvatar;

  const LiveStreamMessageEntity({
    required this.id,
    required this.streamId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });
}
