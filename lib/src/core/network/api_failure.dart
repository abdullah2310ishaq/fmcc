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

class ValidationFailure extends ApiFailure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends ApiFailure {
  const UnknownFailure(super.message);
}

