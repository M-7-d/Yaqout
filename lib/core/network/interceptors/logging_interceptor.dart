import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only interceptor that pretty-prints HTTP requests and responses.
///
/// - Redacts `Authorization` headers to avoid leaking tokens.
/// - Shows request duration.
/// - Completely no-ops in release builds.
class LoggingInterceptor extends Interceptor {
  final Map<int, DateTime> _requestTimestamps = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final id = options.hashCode;
      _requestTimestamps[id] = DateTime.now();

      debugPrint('');
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint('│ ➤ ${options.method.toUpperCase()} ${options.uri}');
      _printHeaders(options.headers);
      if (options.data != null) {
        debugPrint('│ Body: ${_truncate(options.data.toString(), 500)}');
      }
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final id = response.requestOptions.hashCode;
      final duration = _duration(id);

      debugPrint('');
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint(
          '│ ✓ ${response.statusCode} ${response.requestOptions.method.toUpperCase()} '
          '${response.requestOptions.uri}  ($duration)');
      debugPrint(
          '│ Response: ${_truncate(response.data.toString(), 300)}');
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final id = err.requestOptions.hashCode;
      final duration = _duration(id);

      debugPrint('');
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint(
          '│ ✗ ${err.response?.statusCode ?? "N/A"} '
          '${err.requestOptions.method.toUpperCase()} '
          '${err.requestOptions.uri}  ($duration)');
      debugPrint('│ Error: ${err.message}');
      if (err.response?.data != null) {
        debugPrint(
            '│ Body: ${_truncate(err.response!.data.toString(), 300)}');
      }
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    handler.next(err);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _printHeaders(Map<String, dynamic> headers) {
    headers.forEach((key, value) {
      final display = key.toLowerCase() == 'authorization'
          ? '••••••' // Redact token
          : value.toString();
      debugPrint('│ $key: $display');
    });
  }

  String _duration(int requestId) {
    final start = _requestTimestamps.remove(requestId);
    if (start == null) return '?ms';
    return '${DateTime.now().difference(start).inMilliseconds}ms';
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}… (truncated)';
  }
}
