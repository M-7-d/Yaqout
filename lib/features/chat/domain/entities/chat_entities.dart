// Chat domain entities

class ChatRoomEntity {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? productId;
  final DateTime createdAt;

  // Denormalized for UI
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? buyerName;
  final String? sellerName;

  const ChatRoomEntity({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.productId,
    required this.createdAt,
    this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.buyerName,
    this.sellerName,
  });
}

class MessageEntity {
  final String id;
  final String roomId;
  final String senderId;
  final String? content;
  final String? mediaUrl;
  final bool isRead;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.content,
    this.mediaUrl,
    this.isRead = false,
    required this.createdAt,
  });

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
}
