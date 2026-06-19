import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../core/services/notification_service.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.read(sharedPreferencesProvider));
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final SettingsRepository _repo;
  final NotificationService _notificationService;
  final SupabaseClient _supabase;

  SettingsNotifier(this._repo, this._notificationService, this._supabase)
      : super({}) {
    _loadAll();
  }

  /// Notification pref keys that should be synced to Supabase
  static const _notifKeys = [
    'push_notifications',
    'live_stream_notifications',
    'new_followers',
    'likes_comments',
    'ratings_reviews',
    'messages_chat',
    'in_app_sounds',
  ];

  void _loadAll() {
    state = {
      'push_notifications':
          _repo.getBool('push_notifications', defaultValue: true),
      'live_stream_notifications':
          _repo.getBool('live_stream_notifications', defaultValue: true),
      'new_followers': _repo.getBool('new_followers', defaultValue: true),
      'likes_comments': _repo.getBool('likes_comments', defaultValue: true),
      'ratings_reviews': _repo.getBool('ratings_reviews', defaultValue: true),
      'messages_chat': _repo.getBool('messages_chat', defaultValue: true),
      'in_app_sounds': _repo.getBool('in_app_sounds', defaultValue: true),
      'profile_visibility':
          _repo.getString('profile_visibility', defaultValue: 'Public'),
      'message_permission':
          _repo.getString('message_permission', defaultValue: 'Everyone'),
      'live_join_permission':
          _repo.getString('live_join_permission', defaultValue: 'Everyone'),
    };

    // Sync local prefs → Supabase on first load
    _syncToSupabase();
  }

  Future<void> setBool(String key, bool value) async {
    await _repo.setBool(key, value);
    state = {...state, key: value};

    if (key == 'push_notifications') {
      _notificationService.setPushSubscriptionEnabled(value);
    } else if (key == 'live_stream_notifications' ||
        key == 'new_followers' ||
        key == 'likes_comments' ||
        key == 'ratings_reviews' ||
        key == 'messages_chat') {
      _notificationService.updateTag(key, value.toString());
    }

    // Sync this change to Supabase so Edge Functions respect it
    if (_notifKeys.contains(key)) {
      _syncToSupabase();
    }
  }

  Future<void> setString(String key, String value) async {
    await _repo.setString(key, value);
    state = {...state, key: value};
  }

  /// Upserts all notification preference booleans to the
  /// `notification_preferences` table in Supabase.
  Future<void> _syncToSupabase() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final row = <String, dynamic>{'user_id': userId};
      for (final key in _notifKeys) {
        row[key] = state[key] ?? true;
      }

      await _supabase
          .from('notification_preferences')
          .upsert(row, onConflict: 'user_id');
    } catch (e) {
      // Non-fatal — local SharedPreferences still work as a fallback.
      // ignore: avoid_print
      print('[SettingsNotifier] Failed to sync prefs to Supabase: $e');
    }
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier(
    ref.read(settingsRepositoryProvider),
    ref.read(notificationServiceProvider),
    ref.read(supabaseClientProvider),
  );
});
