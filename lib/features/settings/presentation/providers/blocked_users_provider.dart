import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_provider.dart';

class BlockedUser {
  final String id;
  final String name;
  final String? avatarUrl;

  BlockedUser({required this.id, required this.name, this.avatarUrl});

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }
}

class BlockedUsersNotifier extends StateNotifier<List<BlockedUser>> {
  final SettingsRepository _repo;
  static const _key = 'blocked_users_list_v1';

  BlockedUsersNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    final list = _repo.getStringList(_key);
    state = list.map((item) {
      return BlockedUser.fromJson(json.decode(item) as Map<String, dynamic>);
    }).toList();
  }

  Future<void> blockUser(String id, String name, String? avatarUrl) async {
    if (state.any((u) => u.id == id)) return;
    final newUser = BlockedUser(id: id, name: name, avatarUrl: avatarUrl);
    final updated = [...state, newUser];
    state = updated;
    await _save();
  }

  Future<void> unblockUser(String id) async {
    final updated = state.where((u) => u.id != id).toList();
    state = updated;
    await _save();
  }

  bool isBlocked(String id) {
    return state.any((u) => u.id == id);
  }

  Future<void> _save() async {
    final list = state.map((u) => json.encode(u.toJson())).toList();
    await _repo.setStringList(_key, list);
  }
}

final blockedUsersProvider =
    StateNotifierProvider<BlockedUsersNotifier, List<BlockedUser>>((ref) {
  return BlockedUsersNotifier(ref.read(settingsRepositoryProvider));
});
