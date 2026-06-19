// Failure types for clean architecture error handling
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication error.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
