import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../shared/providers/shared_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.read(supabaseClientProvider));
});

// Removed chatRefreshProvider - room-specific streams are already handled
// by the repository's watchMessages() method which uses .stream() with room_id filter

final userRoomsProvider =
    FutureProvider.family<List<ChatRoomEntity>, String>((ref, userId) async {
  return ref.read(chatRepositoryProvider).getUserRooms(userId);
});

final unreadCountProvider = Provider.family<int, String>((ref, userId) {
  final rooms = ref.watch(userRoomsProvider(userId)).valueOrNull ?? [];
  return rooms.fold(0, (sum, room) => sum + room.unreadCount);
});

final chatRoomProvider =
    FutureProvider.family<ChatRoomEntity, String>((ref, roomId) {
  return ref.read(chatRepositoryProvider).getRoomById(roomId);
});

final messagesProvider =
    StreamProvider.family<List<MessageEntity>, String>((ref, roomId) {
  return ref.read(chatRepositoryProvider).watchMessages(roomId);
});

// Chat input state
class ChatInputNotifier extends StateNotifier<String> {
  ChatInputNotifier() : super('');
  void update(String v) => state = v;
  void clear() => state = '';
}

final chatInputProvider =
    StateNotifierProvider.family<ChatInputNotifier, String, String>(
  (ref, roomId) => ChatInputNotifier(),
);
