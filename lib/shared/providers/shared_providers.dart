import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/network/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/network/interceptors/auth_interceptor.dart';
import '../../core/network/interceptors/retry_interceptor.dart';
import '../../core/network/interceptors/error_interceptor.dart';
import '../../core/network/interceptors/logging_interceptor.dart';
import '../../core/storage/hive_storage_service.dart';

// ── Supabase ──────────────────────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// ── Connectivity ──────────────────────────────────────────────────────────────
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(Connectivity());
});

/// Emits `true` when the device has an active connection, `false` otherwise.
/// Use this in the UI to show offline banners, disable buttons, etc.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.read(networkInfoProvider).onConnectivityChanged;
});

// ── Dio ───────────────────────────────────────────────────────────────────────
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: ApiConstants.defaultHeaders,
    ),
  );

  // Order matters:
  //  1. Logging     — logs the raw request before anything modifies it
  //  2. Auth        — attaches JWT token
  //  3. Retry       — retries transient failures
  //  4. Error       — maps remaining errors to domain exceptions (runs last)
  dio.interceptors.addAll([
    LoggingInterceptor(),
    AuthInterceptor(),
    RetryInterceptor(dio: dio),
    ErrorInterceptor(),
  ]);

  return dio;
});

// ── API Client ────────────────────────────────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    dio: ref.read(dioProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

// ── Local Storage ─────────────────────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final hiveStorageProvider = Provider<HiveStorageService>((ref) {
  return HiveStorageService();
});
