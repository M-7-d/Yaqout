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
