import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/storage/hive_storage_service.dart';

class FollowedSellersNotifier extends StateNotifier<List<String>> {
  final HiveStorageService _hiveStorage;
  final SupabaseClient _supabase;
  final String _key;

  FollowedSellersNotifier(this._hiveStorage, this._supabase)
      : _key = _supabase.auth.currentUser?.id != null
            ? 'followed_sellers_${_supabase.auth.currentUser!.id}'
            : 'followed_sellers_anonymous',
        super([]) {
    if (_supabase.auth.currentUser?.id != null) {
      state = _hiveStorage.getSetting(_key, defaultValue: <String>[]) as List<String>;
      _syncFromSupabase();
    }
  }

  /// On startup, sync follows from Supabase so they persist across devices/reinstalls.
  Future<void> _syncFromSupabase() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('follows')
          .select('seller_id')
          .eq('follower_id', userId);

      final remoteIds =
          (data as List).map((e) => e['seller_id'] as String).toList();

      state = remoteIds;
      await _hiveStorage.setSetting(_key, remoteIds);
    } catch (_) {
      // Fail silently — local state is already loaded from hive
    }
  }

  Future<void> toggleFollow(String sellerId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be logged in to follow sellers.');
    }

    final isFollowing = state.contains(sellerId);
    final previousState = state;

    // Optimistically update local state
    if (isFollowing) {
      state = state.where((id) => id != sellerId).toList();
    } else {
      if (!state.contains(sellerId)) {
        state = [...state, sellerId];
      }
    }
    await _hiveStorage.setSetting(_key, state);

    try {
      if (isFollowing) {
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', userId)
            .eq('seller_id', sellerId);
      } else {
        await _supabase.from('follows').upsert({
          'follower_id': userId,
          'seller_id': sellerId,
        });
      }
    } catch (e) {
      // Revert state on error
      state = previousState;
      await _hiveStorage.setSetting(_key, state);
      rethrow;
    }
  }
}

final followedSellersProvider =
    StateNotifierProvider<FollowedSellersNotifier, List<String>>((ref) {
  final hiveStorage = ref.watch(hiveStorageProvider);
  final supabase = ref.watch(supabaseClientProvider);

  // Watch auth state changes so this provider is recreated
  // when a different user logs in/out.
  ref.watch(authNotifierProvider);

  return FollowedSellersNotifier(hiveStorage, supabase);
});
