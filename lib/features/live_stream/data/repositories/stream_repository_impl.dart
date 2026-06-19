import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/live_stream_message_entity.dart';
import '../../domain/repositories/stream_repository.dart';
import '../models/live_stream_model.dart';
import '../models/live_stream_message_model.dart';
import '../../../../core/errors/exceptions.dart';

class StreamRepositoryImpl implements StreamRepository {
  final SupabaseClient _client;
  StreamRepositoryImpl(this._client);

  @override
  Future<LiveStreamEntity> createStream({
    required String sellerId,
    required String title,
    String? productId,
    DateTime? scheduledAt,
  }) async {
    try {
      final channelName = const Uuid().v4().replaceAll('-', '').substring(0, 16);
      final status = scheduledAt == null ? 'live' : 'scheduled';
      final data = await _client.from('live_streams').insert({
        'seller_id':    sellerId,
        'title':        title,
        'product_id':   productId,
        'agora_channel':channelName,
        'status':       status,
        'started_at':   status == 'live' ? DateTime.now().toIso8601String() : null,
        'last_heartbeat_at': status == 'live' ? DateTime.now().toIso8601String() : null,
        'scheduled_at': scheduledAt?.toIso8601String(),
      }).select().single();
      return LiveStreamModel.fromJson(data).toEntity();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> getAgoraToken(
    String channelName,
    int uid, {
    bool isHost = true,
  }) async {
    try {
      // Calls a Supabase Edge Function: supabase/functions/agora-token/index.ts
      final response = await _client.functions.invoke(
        'agora-token',
        body: {
          'channelName': channelName,
          'uid':         uid,
          'role':        isHost ? 'publisher' : 'subscriber',
        },
      );
      return response.data['token'] as String;
    } catch (e) {
      throw ServerException(message: 'Failed to fetch Agora token: $e');
    }
  }

  @override
  Stream<LiveStreamEntity> watchStreamById(String id) {
    return _client
        .from('live_streams')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) {
          // data is a List of records, take the first one
          final record = (data as List).first;
          return LiveStreamModel.fromJson(record).toEntity();
        });
  }

  @override
  Future<void> blockUser({
    required String streamId,
    required String blockedUserId,
    required String blockedById,
  }) async {
    try {
      await _client.from('live_stream_blocks').insert({
        'stream_id': streamId,
        'blocked_user_id': blockedUserId,
        'blocked_by_id': blockedById,
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> addLike({
    required String streamId,
    required String userId,
  }) async {
    try {
      await _client.from('live_stream_likes').insert({
        'stream_id': streamId,
        'user_id': userId,
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

// Deprecated likeStream method removed; use addLike instead



  @override
  Future<void> updateStreamStatus(String streamId, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'live') {
      updates['started_at'] = DateTime.now().toIso8601String();
      updates['last_heartbeat_at'] = DateTime.now().toIso8601String();
    }
    if (status == 'ended') updates['ended_at']   = DateTime.now().toIso8601String();
    await _client.from('live_streams').update(updates).eq('id', streamId);
  }

  @override
  Future<void> updateHeartbeat(String streamId) async {
    await _client.rpc('update_stream_heartbeat', params: {'p_stream_id': streamId});
  }

  @override
  Future<void> incrementViewerCount(String streamId) async {
    await _client.rpc('increment_viewer_count', params: {'stream_id': streamId});
  }

  @override
  Future<void> decrementViewerCount(String streamId) async {
    await _client.rpc('decrement_viewer_count', params: {'stream_id': streamId});
  }

  @override
  Stream<List<LiveStreamEntity>> watchLiveStreams() {
    return _client
        .from('live_streams')
        .stream(primaryKey: ['id'])
        .map((data) =>
            data.map((e) => LiveStreamModel.fromJson(e).toEntity())
                .where((e) => e.status == 'live')
                .toList());
  }

  @override
  Future<LiveStreamEntity> getStreamById(String id) async {
    final data = await _client
        .from('live_streams')
        .select('*, profiles(*)')
        .eq('id', id)
        .single();
    return LiveStreamModel.fromJson(data).toEntity();
  }

@override
  Stream<bool> watchUserBlock(String streamId, String userId) {
    return _client
        .from('live_stream_blocks')
        .stream(primaryKey: ['id'])
        .eq('stream_id', streamId)
        .map((data) {
          final List<dynamic> list = data as List<dynamic>;
          return list.any((e) => e['blocked_user_id'] == userId);
        });
  }

  @override
  Future<void> sendMessage({
    required String streamId,
    required String senderId,
    required String content,
  }) async {
    try {
      await _client.from('live_stream_messages').insert({
        'stream_id': streamId,
        'sender_id': senderId,
        'content': content,
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<LiveStreamMessageEntity>> watchMessages(String streamId) {
    return _client
        .from('live_stream_messages')
        .stream(primaryKey: ['id'])
        .eq('stream_id', streamId)
        .map((data) {
          final list = data
              .map((e) => LiveStreamMessageModel.fromRawJson(e).toEntity())
              .toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }
}
