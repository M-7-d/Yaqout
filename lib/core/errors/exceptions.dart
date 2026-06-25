class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({this.message = 'Server error', this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException({this.message = 'Auth error'});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'Network error'});
}

class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'Cache error'});
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException({this.message = 'Not found'});
}

class StorageException implements Exception {
  final String message;
  const StorageException({this.message = 'Storage error'});
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException({this.message = 'Request timed out'});

  @override
  String toString() => 'TimeoutException: $message';
}

class RateLimitException implements Exception {
  final String message;
  const RateLimitException({this.message = 'Too many requests'});

  @override
  String toString() => 'RateLimitException: $message';
}
