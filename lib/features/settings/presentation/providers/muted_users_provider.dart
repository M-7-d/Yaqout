import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/settings_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/shared_providers.dart';
import 'settings_provider.dart';

class MutedUser {
  final String id;
  final String name;

  MutedUser({required this.id, required this.name});

  factory MutedUser.fromJson(Map<String, dynamic> json) {
    return MutedUser(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class MutedUsersNotifier extends StateNotifier<List<MutedUser>> {
  final SettingsRepository _repo;
  final SupabaseClient _supabase;
  static const _key = 'muted_users_list_v1';

  MutedUsersNotifier(this._repo, this._supabase) : super([]) {
    _load();
  }

  void _load() {
    final list = _repo.getStringList(_key);
    state = list.map((item) {
      return MutedUser.fromJson(json.decode(item) as Map<String, dynamic>);
    }).toList();
  }

  Future<void> muteUser(String id, String name) async {
    if (state.any((u) => u.id == id)) return;
    final newUser = MutedUser(id: id, name: name);
    final updated = [...state, newUser];
    state = updated;
    await _save();

    // Also add to chat_mutes in Supabase
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        await _supabase.from('chat_mutes').upsert({
          'muted_by_id': currentUserId,
          'muted_user_id': id,
        });
      }
    } catch (e) {
      // Ignore errors if it fails or doesn't exist
    }
  }

  Future<void> unmuteUser(String id) async {
    final updated = state.where((u) => u.id != id).toList();
    state = updated;
    await _save();
    
    // Also remove from chat_mutes in Supabase
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        await _supabase
            .from('chat_mutes')
            .delete()
            .match({
              'muted_by_id': currentUserId,
              'muted_user_id': id,
            });
      }
    } catch (e) {
      // Ignore errors if it fails or doesn't exist
    }
  }

  bool isMuted(String id) {
    return state.any((u) => u.id == id);
  }

  Future<void> _save() async {
    final list = state.map((u) => json.encode(u.toJson())).toList();
    await _repo.setStringList(_key, list);
  }
}

final mutedUsersProvider =
    StateNotifierProvider<MutedUsersNotifier, List<MutedUser>>((ref) {
  return MutedUsersNotifier(
    ref.read(settingsRepositoryProvider),
    ref.read(supabaseClientProvider),
  );
});
