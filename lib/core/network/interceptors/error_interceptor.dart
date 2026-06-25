import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

/// Interceptor that maps [DioException] responses to typed app exceptions.
///
/// This runs **last** in the interceptor chain so that auth refresh and
/// retries have already been attempted before the error reaches here.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const TimeoutException(
          message: 'Request timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        throw const NetworkException(
          message: 'No internet connection. Please check your network.',
        );

      case DioExceptionType.badResponse:
        _handleBadResponse(err);
        break;

      case DioExceptionType.cancel:
        throw const ServerException(message: 'Request was cancelled.');

      case DioExceptionType.badCertificate:
        throw const ServerException(
          message: 'SSL certificate error. Connection is not secure.',
        );

      case DioExceptionType.unknown:
        throw ServerException(
          message: err.message ?? 'An unexpected error occurred.',
        );
    }

    // Fallback — should not be reached
    handler.next(err);
  }

  void _handleBadResponse(DioException err) {
    final statusCode = err.response?.statusCode ?? 0;
    final data = err.response?.data;

    // Try to extract a message from the response body
    String message = 'Server error';
    if (data is Map<String, dynamic>) {
      message = (data['message'] ?? data['error'] ?? data['msg'] ?? 'Server error')
          .toString();
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    switch (statusCode) {
      case 400:
        throw ServerException(message: message, statusCode: 400);
      case 401:
        throw AuthException(message: 'Unauthorized: $message');
      case 403:
        throw AuthException(message: 'Forbidden: $message');
      case 404:
        throw NotFoundException(message: message);
      case 409:
        throw ServerException(message: 'Conflict: $message', statusCode: 409);
      case 422:
        throw ServerException(
            message: 'Validation error: $message', statusCode: 422);
      case 429:
        throw const RateLimitException(message: 'Too many requests. Please slow down.');
      default:
        if (statusCode >= 500) {
          throw ServerException(
              message: 'Server error ($statusCode): $message',
              statusCode: statusCode);
        }
        throw ServerException(message: message, statusCode: statusCode);
    }
  }
}
