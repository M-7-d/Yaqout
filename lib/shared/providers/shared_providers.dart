import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.addAll([
    LogInterceptor(requestBody: true, responseBody: true),
    InterceptorsWrapper(
      onError: (DioException e, handler) {
        // Global error handling — add auth refresh here if needed
        return handler.next(e);
      },
    ),
  ]);
  return dio;
});
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});
