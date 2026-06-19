import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FollowedSellersNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;
  final SupabaseClient _supabase;
  static const _key = 'followed_sellers';

  FollowedSellersNotifier(this._prefs, this._supabase)
      : super(_prefs.getStringList(_key) ?? []) {
    _syncFromSupabase();
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
    final isFollowing = state.contains(sellerId);

    // Optimistically update local state
    if (isFollowing) {
      state = state.where((id) => id != sellerId).toList();
    } else {
      state = [...state, sellerId];
    }
    await _prefs.setStringList(_key, state);

    // Sync to Supabase (if user is logged in)
    if (userId == null) return;
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
    } catch (_) {
      // Fail silently — local state is already updated
    }
  }
}

final followedSellersProvider =
    StateNotifierProvider<FollowedSellersNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return FollowedSellersNotifier(prefs, supabase);
});
