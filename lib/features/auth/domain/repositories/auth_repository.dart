import 'dart:io';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Upload a profile avatar and return its public URL.
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  });

  /// Returns the signed-in [UserEntity] or throws [AuthException].
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  /// Creates an account and profile row; returns the new [UserEntity].
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String role,
    String? fullName,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);
  Future<void> verifyPasswordResetCode({required String email, required String code});
  Future<void> updatePassword(String newPassword);

  /// Emits the current user whenever auth state changes; null = signed out.
  Stream<UserEntity?> get authStateChanges;

  Future<UserEntity?> getCurrentUser();

  /// Fetch a user by ID (e.g., for seller profiles).
  Future<UserEntity?> getUserById(String userId);

  Future<UserEntity> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? address,
    String? shopDescription,
    String? role,
  });
}
