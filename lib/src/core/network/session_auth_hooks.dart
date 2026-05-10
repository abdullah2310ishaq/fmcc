/// Lets [ApiClient] refresh bearer tokens on 401 without a circular import.
abstract class SessionAuthHooks {
  String? get accessToken;
  String? get refreshToken;

  /// Single-flight refresh; returns `true` when new tokens were persisted.
  Future<bool> tryRefreshTokensLocked();

  /// Clears auth after refresh failure or repeated 401.
  Future<void> logoutDueToExpiredSession();
}
