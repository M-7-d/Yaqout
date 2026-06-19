import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../core/services/notification_service.dart';


// ── Repository provider ───────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(supabaseClientProvider));
});

// ── Auth state stream ─────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

// ── Current user (one-shot fetch) ─────────────────────────────────────────────
final currentUserProvider = FutureProvider<UserEntity?>((ref) {
  return ref.read(authRepositoryProvider).getCurrentUser();
});

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepository _repo;
  final NotificationService _notificationService;
  AuthNotifier(this._repo, this._notificationService) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final user = await _repo.getCurrentUser();
    if (user != null) {
      _notificationService.loginUser(user.id);
    }
    state = AsyncValue.data(user);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _repo.signIn(email: email, password: password));
    if (state.valueOrNull != null) {
      _notificationService.loginUser(state.valueOrNull!.id);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signUp(
          email: email, password: password, role: role, fullName: fullName),
    );
    if (state.valueOrNull != null) {
      _notificationService.loginUser(state.valueOrNull!.id);
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? address,
    String? shopDescription,
    String? role,
  }) async {
    final prevState = state;
    try {
      final updatedUser = await _repo.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
        address: address,
        shopDescription: shopDescription,
        role: role,
      );
      state = AsyncValue.data(updatedUser.copyWith(email: prevState.valueOrNull?.email));  
    } catch (e, st) {
      state = prevState;
      throw e;
    }
  }

  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    return await _repo.uploadAvatar(userId: userId, file: file);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _notificationService.logoutUser();
    state = const AsyncValue.data(null);
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _repo.sendPasswordReset(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyCode(String email, String code) async {
    try {
      await _repo.verifyPasswordResetCode(email: email, code: code);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updatePassword(newPassword);
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(notificationServiceProvider),
  );
});

// ── Fetch user by ID (for seller profile, etc) ────────────────────────────────
final userByIdProvider =
    FutureProvider.family<UserEntity?, String>((ref, userId) {
  return ref.read(authRepositoryProvider).getUserById(userId);
});
