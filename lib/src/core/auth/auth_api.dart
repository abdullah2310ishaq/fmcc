import 'package:doctor_app/src/core/auth/auth_models.dart';
import 'package:doctor_app/src/core/auth/jwt_utils.dart';
import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/endpoints.dart';
import 'package:doctor_app/src/core/roles/role_ids.dart';
import 'package:doctor_app/src/core/session/app_session.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthSession> googleLogin({
    required String idToken,
    required UserRole role,
  }) async {
    final res = await _client.post(
      Endpoints.googleLogin,
      body: {
        'IdToken': idToken,
        'RoleId': RoleIds.fromRole(role),
      },
    );

    final dynamic data = res.data;
    final token = _extractToken(data);
    if (token == null || token.trim().isEmpty) {
      throw StateError('Login succeeded but token was not found in response.');
    }

    final refreshToken = _extractRefreshToken(data);

    final payload = JwtUtils.tryDecodePayload(token);
    final userId = (payload['name'] ?? payload['Name'] ?? payload['sub'] ?? payload['Sub'])?.toString();
    final isVerifiedRaw = payload['IsVerified'] ?? payload['isVerified'];
    final isVerified = _toBool(isVerifiedRaw);

    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Login succeeded but user id was not found in token.');
    }

    return AuthSession(
      accessToken: token,
      userId: userId,
      isVerified: isVerified,
      refreshToken: refreshToken,
    );
  }

  /// Matches backend `AuthController.Refresh` / `TokenRequestModel`.
  Future<AuthSession> refreshTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final res = await _client.post(
      Endpoints.refreshToken,
      body: {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      },
      skipAuthRetry: true,
    );

    final dynamic data = res.data;
    final token = _extractToken(data);
    if (token == null || token.trim().isEmpty) {
      throw StateError('Refresh succeeded but access token was missing.');
    }

    final nextRefresh = _extractRefreshToken(data) ?? refreshToken;

    final payload = JwtUtils.tryDecodePayload(token);
    final userId = (payload['name'] ?? payload['Name'] ?? payload['sub'] ?? payload['Sub'])?.toString();
    final isVerifiedRaw = payload['IsVerified'] ?? payload['isVerified'];
    final isVerified = _toBool(isVerifiedRaw);

    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Refresh succeeded but user id was not found in token.');
    }

    return AuthSession(
      accessToken: token,
      userId: userId,
      isVerified: isVerified,
      refreshToken: nextRefresh,
    );
  }

  static String? _extractToken(dynamic data) {
    if (data is String) return data;
    if (data is Map) {
      final token = data['token'] ?? data['Token'] ?? data['accessToken'] ?? data['AccessToken'];
      if (token is String && token.trim().isNotEmpty) return token.trim();

      final inner = data['data'] ?? data['Data'] ?? data['result'] ?? data['Result'];
      if (inner is Map) {
        final token2 =
            inner['token'] ?? inner['Token'] ?? inner['accessToken'] ?? inner['AccessToken'];
        if (token2 is String && token2.trim().isNotEmpty) return token2.trim();
      }
    }
    return null;
  }

  static String? _extractRefreshToken(dynamic data) {
    if (data is! Map) return null;
    final rt = data['refreshToken'] ?? data['RefreshToken'];
    if (rt is String && rt.trim().isNotEmpty) return rt.trim();

    final inner = data['data'] ?? data['Data'] ?? data['result'] ?? data['Result'];
    if (inner is Map) {
      final rt2 = inner['refreshToken'] ?? inner['RefreshToken'];
      if (rt2 is String && rt2.trim().isNotEmpty) return rt2.trim();
    }
    return null;
  }

  static bool _toBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'yes' || v == 'y';
    }
    return false;
  }
}

