import 'dart:io';
import '../entities/chat_entities.dart';

abstract class ChatRepository {
  Future<ChatRoomEntity> getOrCreateRoom({
    required String buyerId,
    required String sellerId,
    String? productId,
  });

  Stream<List<MessageEntity>> watchMessages(String roomId);

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    String? content,
    File? media,
  });

  Future<List<ChatRoomEntity>> getUserRooms(String userId);

  Future<ChatRoomEntity> getRoomById(String roomId);

  Future<void> markRoomAsRead(String roomId, String userId);
}
