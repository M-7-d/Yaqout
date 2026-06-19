import '../../domain/entities/chat_entities.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.roomId,
    required super.senderId,
    super.content,
    super.mediaUrl,
    super.isRead,
    required super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id:       j['id'] as String,
        roomId:   j['room_id'] as String,
        senderId: j['sender_id'] as String,
        content:  j['content'] as String?,
        mediaUrl: j['media_url'] as String?,
        isRead:   j['is_read'] as bool? ?? false,
        createdAt:DateTime.parse(j['created_at'] as String),
      );

  MessageEntity toEntity() => MessageEntity(
        id:        id,
        roomId:    roomId,
        senderId:  senderId,
        content:   content,
        mediaUrl:  mediaUrl,
        isRead:    isRead,
        createdAt: createdAt,
      );
}

class ChatRoomModel extends ChatRoomEntity {
  const ChatRoomModel({
    required super.id,
    required super.buyerId,
    required super.sellerId,
    super.productId,
    required super.createdAt,
    super.otherUserName,
    super.otherUserAvatar,
    super.lastMessage,
    super.lastMessageAt,
    super.unreadCount,
    super.buyerName,
    super.sellerName,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> j, {String? currentUserId}) {
    final buyerMap = j['buyer'] as Map<String, dynamic>?;
    final sellerMap = j['seller'] as Map<String, dynamic>?;
    final buyerName = buyerMap?['full_name'] as String?;
    final sellerName = sellerMap?['full_name'] as String?;

    String? otherUserName;
    String? otherUserAvatar;

    if (currentUserId != null) {
      final buyerId = j['buyer_id'] as String;
      if (currentUserId == buyerId) {
        otherUserName = sellerMap?['full_name'] as String?;
        otherUserAvatar = sellerMap?['avatar_url'] as String?;
      } else {
        otherUserName = buyerMap?['full_name'] as String?;
        otherUserAvatar = buyerMap?['avatar_url'] as String?;
      }
    }

    String? lastMessage;
    DateTime? lastMessageAt;
    int unreadCount = 0;

    final messagesList = j['messages'] as List?;
    if (messagesList != null && messagesList.isNotEmpty) {
      final msgList = messagesList.map((m) => m as Map<String, dynamic>).toList();
      msgList.sort((a, b) => DateTime.parse(b['created_at'] as String).compareTo(DateTime.parse(a['created_at'] as String)));
      
      final latestMsg = msgList.first;
      lastMessage = latestMsg['content'] as String? ?? (latestMsg['media_url'] != null ? '[Image]' : null);
      lastMessageAt = DateTime.parse(latestMsg['created_at'] as String);

      if (currentUserId != null) {
        unreadCount = msgList.where((m) {
          final isRead = m['is_read'] as bool? ?? false;
          final senderId = m['sender_id'] as String;
          return !isRead && senderId != currentUserId;
        }).length;
      }
    }

    return ChatRoomModel(
      id:        j['id'] as String,
      buyerId:   j['buyer_id'] as String,
      sellerId:  j['seller_id'] as String,
      productId: j['product_id'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      buyerName: buyerName,
      sellerName: sellerName,
    );
  }
}
