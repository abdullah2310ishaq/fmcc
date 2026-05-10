class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.isVerified,
    this.refreshToken,
  });

  final String accessToken;
  final String userId;
  final bool isVerified;
  final String? refreshToken;
}

