sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Internal server error']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);

  final List<String> details = const [];

  factory ValidationFailure.withDetails({
    required String message,
    List<String> details = const [],
  }) {
    return _ValidationFailureWithDetails(message, details);
  }
}

class _ValidationFailureWithDetails extends ValidationFailure {
  @override
  final List<String> details;

  const _ValidationFailureWithDetails(String message, this.details)
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication error']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Conflict']);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure(
      [super.message = 'Access denied. Please contact support.']);
}
