class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.isVerified,
  });

  final String accessToken;
  final String userId;
  final bool isVerified;
}

