sealed class ApiFailure {
  const ApiFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends ApiFailure {
  const NetworkFailure(super.message);
}

class ServerFailure extends ApiFailure {
  const ServerFailure(super.message);
}

class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure(super.message);
}

/// After failed refresh / forced logout — avoids exposing HTTP status text.
class SessionEndedFailure extends ApiFailure {
  const SessionEndedFailure([
    super.message =
        'Your session ended. Please sign in again. • سیشن ختم ہو گیا، دوبارہ سائن اِن کریں۔',
  ]);
}

class ValidationFailure extends ApiFailure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends ApiFailure {
  const UnknownFailure(super.message);
}

