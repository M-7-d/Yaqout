import 'package:dio/dio.dart';
import 'network_info.dart';
import '../../core/errors/exceptions.dart';

/// Production-grade HTTP client wrapping [Dio].
///
/// Provides typed helper methods (`get`, `post`, `put`, `patch`, `delete`)
/// and pre-checks network connectivity before every request.
///
/// All interceptors (auth, retry, error mapping, logging) are
/// configured via the injected [Dio] instance — this class stays
/// focused on convenience and connectivity gating.
class ApiClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;

  ApiClient({
    required Dio dio,
    required NetworkInfo networkInfo,
  })  : _dio = dio,
        _networkInfo = networkInfo;

  /// Exposes the underlying [Dio] instance for advanced use cases
  /// (e.g., download, streaming).
  Dio get dio => _dio;

  // ── GET ────────────────────────────────────────────────────────────────────

  /// Sends a GET request to [path] and returns the response data.
  ///
  /// Throws [NetworkException] when offline.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ── POST ───────────────────────────────────────────────────────────────────

  /// Sends a POST request to [path] with an optional [data] body.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ── PUT ────────────────────────────────────────────────────────────────────

  /// Sends a PUT request to [path] with an optional [data] body.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ── PATCH ──────────────────────────────────────────────────────────────────

  /// Sends a PATCH request to [path] with an optional [data] body.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────

  /// Sends a DELETE request to [path].
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  /// Throws [NetworkException] when the device is offline.
  Future<void> _checkConnectivity() async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      throw const NetworkException(
        message: 'No internet connection. Please check your network.',
      );
    }
  }
}
