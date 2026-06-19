import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/errors/exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;
  AuthRepositoryImpl(this._client);

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null)
        throw const AuthException(message: 'Login failed.');
      return await _fetchProfile(
          response.user!.id, response.user!.email ?? email);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String role,
    String? fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );
      if (response.user == null)
        throw const AuthException(message: 'Sign-up failed.');

      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'role': role,
        'full_name': fullName,
        'email': email,
      });

      return await _fetchProfile(response.user!.id, email);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email);

  @override
  Future<void> verifyPasswordResetCode({required String email, required String code}) async {
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges =>
      _client.auth.onAuthStateChange.asyncMap((event) async {
        if (event.session == null) return null;
        final user = event.session!.user;
        return _fetchProfile(user.id, user.email ?? '');
      });

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id, user.email ?? '');
  }

  @override
  Future<UserEntity?> getUserById(String userId) async {
    return _fetchProfile(userId, '');
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    try {
      final safeName = _basename(file.path);
      final path = 'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      await _client.storage.from('avatars').upload(
            path, file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserEntity> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? address,
    String? shopDescription,
    String? role,
  }) async {
    final data = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (address != null) 'address': address,
      if (shopDescription != null) 'shop_description': shopDescription,
      if (role != null) 'role': role,
    };

    if (data.isNotEmpty) {
      await _client.from('profiles').update(data).eq('id', userId);
    }
    return _fetchProfile(userId, '');
  }

  Future<UserEntity> _fetchProfile(String id, String email) async {
    final data =
        await _client.from('profiles').select().eq('id', id).maybeSingle();

    if (data == null) {
      return UserEntity(id: id, email: email, role: 'buyer');
    }
    return UserModel.fromJson({...data, 'email': email}).toEntity();
  }
}

String _basename(String filePath) {
  final normalized = filePath.replaceAll(r'\', '/');
  final i = normalized.lastIndexOf('/');
  return i >= 0 ? normalized.substring(i + 1) : normalized;
}
