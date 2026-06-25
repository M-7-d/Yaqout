import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import '../api_constants.dart';

/// Interceptor that retries failed requests with exponential backoff.
///
/// Only retries on:
/// - Connection timeouts / receive timeouts
/// - 5xx server errors
/// - Connection errors (no internet momentarily)
///
/// POST requests are **not** retried by default to avoid
/// duplicate side effects. Mark a request as safe-to-retry by
/// setting `options.extra['retryable'] = true`.
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  final Duration _baseDelay;

  RetryInterceptor({
    required Dio dio,
    int? maxRetries,
    Duration? baseDelay,
  })  : _dio = dio,
        _maxRetries = maxRetries ?? ApiConstants.maxRetries,
        _baseDelay = baseDelay ?? ApiConstants.retryBaseDelay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['_retryAttempt'] as int?) ?? 0;

    if (attempt >= _maxRetries || !_shouldRetry(err)) {
      return handler.next(err);
    }

    // Exponential backoff: 1s → 2s → 4s …
    final delay = _baseDelay * pow(2, attempt).toInt();
    await Future.delayed(delay);

    // Mark the retry attempt number
    err.requestOptions.extra['_retryAttempt'] = attempt + 1;

    try {
      final response = await _dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    // Don't retry non-idempotent methods unless explicitly marked
    final method = err.requestOptions.method.toUpperCase();
    if (method == 'POST' || method == 'PATCH') {
      final retryable = err.requestOptions.extra['retryable'] as bool?;
      if (retryable != true) return false;
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        return statusCode >= 500;
      default:
        return false;
    }
  }
}
