import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_models.dart';
import '../../../../core/errors/exceptions.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient _client;
  ChatRepositoryImpl(this._client);

  static const _bucket = 'chat-media';

  @override
  Future<ChatRoomEntity> getOrCreateRoom({
    required String buyerId,
    required String sellerId,
    String? productId,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      // Check existing room
      var q = _client
          .from('chat_rooms')
          .select('''
            *,
            buyer:profiles!buyer_id(full_name, avatar_url),
            seller:profiles!seller_id(full_name, avatar_url),
            messages(content, media_url, created_at, is_read, sender_id)
          ''')
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId);
      if (productId != null) q = q.eq('product_id', productId);

      final existing = await q.maybeSingle();
      if (existing != null) return ChatRoomModel.fromJson(existing, currentUserId: currentUserId);

      // Create new room
      final data = await _client
          .from('chat_rooms')
          .insert({
            'buyer_id':   buyerId,
            'seller_id':  sellerId,
            'product_id': productId,
          })
          .select('''
            *,
            buyer:profiles!buyer_id(full_name, avatar_url),
            seller:profiles!seller_id(full_name, avatar_url),
            messages(content, media_url, created_at, is_read, sender_id)
          ''')
          .single();
      return ChatRoomModel.fromJson(data, currentUserId: currentUserId);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String roomId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((data) {
      final list = data.map((e) => MessageModel.fromJson(e).toEntity()).toList();
      // Sort descending (newest first)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    String? content,
    File? media,
  }) async {
    try {
      String? mediaUrl;
      if (media != null) {
        final safeName = _basename(media.path);
        final path =
            '$roomId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
        await _client.storage
            .from(_bucket)
            .upload(path, media,
                fileOptions: const FileOptions(cacheControl: '3600'));
        // chat-media is a private bucket — use signed URL (1 year TTL)
        mediaUrl = await _client.storage
            .from(_bucket)
            .createSignedUrl(path, 60 * 60 * 24 * 365);
      }

      await _client.from('messages').insert({
        'room_id':   roomId,
        'sender_id': senderId,
        'content':   content,
        'media_url': mediaUrl,
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ChatRoomEntity> getRoomById(String roomId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      final data = await _client
          .from('chat_rooms')
          .select('''
            *,
            buyer:profiles!buyer_id(full_name, avatar_url),
            seller:profiles!seller_id(full_name, avatar_url),
            messages(content, media_url, created_at, is_read, sender_id)
          ''')
          .eq('id', roomId)
          .single();
      return ChatRoomModel.fromJson(data, currentUserId: currentUserId);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ChatRoomEntity>> getUserRooms(String userId) async {
    try {
      final data = await _client
          .from('chat_rooms')
          .select('''
            *,
            buyer:profiles!buyer_id(full_name, avatar_url),
            seller:profiles!seller_id(full_name, avatar_url),
            messages(content, media_url, created_at, is_read, sender_id)
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>, currentUserId: userId))
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> markRoomAsRead(String roomId, String userId) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('room_id', roomId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }
}

String _basename(String filePath) {
  final normalized = filePath.replaceAll(r'\', '/');
  final i = normalized.lastIndexOf('/');
  return i >= 0 ? normalized.substring(i + 1) : normalized;
}
