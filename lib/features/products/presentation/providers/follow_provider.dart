import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FollowedSellersNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;
  final SupabaseClient _supabase;
  final String _key;

  FollowedSellersNotifier(this._prefs, this._supabase)
      : _key = _supabase.auth.currentUser?.id != null
            ? 'followed_sellers_${_supabase.auth.currentUser!.id}'
            : 'followed_sellers_anonymous',
        super([]) {
    if (_supabase.auth.currentUser?.id != null) {
      state = _prefs.getStringList(_key) ?? [];
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
      await _prefs.setStringList(_key, remoteIds);
    } catch (_) {
      // Fail silently — local state is already loaded from prefs
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
    await _prefs.setStringList(_key, state);

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
      await _prefs.setStringList(_key, state);
      rethrow;
    }
  }
}

final followedSellersProvider =
    StateNotifierProvider<FollowedSellersNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final supabase = ref.watch(supabaseClientProvider);
  
  // Watch auth state changes so this provider is recreated
  // when a different user logs in/out.
  ref.watch(authNotifierProvider);

  return FollowedSellersNotifier(prefs, supabase);
});
