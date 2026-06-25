import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'message_adapter.g.dart';

@HiveType(typeId: 0)
class HiveMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String roomId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String? content;

  @HiveField(4)
  final String? mediaUrl;

  @HiveField(5)
  final bool isRead;

  @HiveField(6)
  final DateTime createdAt;

  HiveMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.content,
    this.mediaUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory HiveMessage.fromJson(Map<String, dynamic> json) {
    return HiveMessage(
      id: json['id'] as String? ?? const Uuid().v4(),
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'media_url': mediaUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
