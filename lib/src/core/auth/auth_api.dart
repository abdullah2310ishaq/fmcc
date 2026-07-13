import 'package:doctor_app/src/core/auth/auth_models.dart';
import 'package:doctor_app/src/core/auth/jwt_utils.dart';
import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/network/endpoints.dart';
import 'package:doctor_app/src/core/roles/role_ids.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  static const doctorNotVerifiedMessage =
      'You are not verified. Please contact the administration.';

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

    AppLogger.instance.i(
      '[AUTH] google-login request role=$role roleId=${RoleIds.fromRole(role)}',
    );

    final dynamic data = res.data;

    if (role == UserRole.doctor && _isExplicitNullProfile(data)) {
      throw const ValidationFailure(doctorNotVerifiedMessage);
    }

    final token = _extractToken(data);
    if (token == null || token.trim().isEmpty) {
      if (role == UserRole.doctor) {
        throw const ValidationFailure(doctorNotVerifiedMessage);
      }
      throw StateError('Login succeeded but token was not found in response.');
    }

    final refreshToken = _extractRefreshToken(data);

    final payload = JwtUtils.tryDecodePayload(token);
    final userId = _extractUserId(data) ??
        (payload['name'] ??
                payload['Name'] ??
                payload['sub'] ??
                payload['Sub'])
            ?.toString();

    final isVerifiedRaw = payload['IsVerified'] ?? payload['isVerified'];
    final isVerified =
        _extractIsVerified(data) ?? _toBool(isVerifiedRaw);

    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Login succeeded but user id was not found in token.');
    }

    DoctorProfileFields? doctorProfile;
    if (role == UserRole.doctor) {
      // Login may return only `UserLoginResponse` (token + userId). Doctor
      // fields are loaded from profile API in SessionController when missing.
      doctorProfile = _extractDoctorProfile(data, fallbackUserId: userId);
    }

    return AuthSession(
      accessToken: token,
      userId: userId,
      isVerified: isVerified,
      refreshToken: refreshToken,
      doctorProfile: doctorProfile,
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
    final userId = _extractUserId(data) ??
        (payload['name'] ??
                payload['Name'] ??
                payload['sub'] ??
                payload['Sub'])
            ?.toString();
    final isVerifiedRaw = payload['IsVerified'] ?? payload['isVerified'];
    final isVerified =
        _extractIsVerified(data) ?? _toBool(isVerifiedRaw);

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

  static bool _isExplicitNullProfile(dynamic data) {
    if (data == null) return true;
    if (data is! Map) return false;
    final m = Map<String, dynamic>.from(data);
    if (!m.containsKey('data') &&
        !m.containsKey('Data') &&
        !m.containsKey('result') &&
        !m.containsKey('Result')) {
      return false;
    }
    final inner = m['data'] ?? m['Data'] ?? m['result'] ?? m['Result'];
    return inner == null;
  }

  static DoctorProfileFields? _extractDoctorProfile(
    dynamic data, {
    String? fallbackUserId,
  }) {
    if (data is! Map) return null;
    final m = Map<String, dynamic>.from(data);
    final candidates = <Map<String, dynamic>>[m];

    for (final key in [
      'data',
      'Data',
      'result',
      'Result',
      'doctor',
      'Doctor',
      'profile',
      'Profile',
    ]) {
      final inner = m[key];
      if (inner is Map) {
        candidates.add(Map<String, dynamic>.from(inner));
        final nested = Map<String, dynamic>.from(inner);
        for (final nestedKey in ['doctor', 'Doctor', 'profile', 'Profile']) {
          final deeper = nested[nestedKey];
          if (deeper is Map) {
            candidates.add(Map<String, dynamic>.from(deeper));
          }
        }
      }
    }

    DoctorProfileFields? best;
    for (final candidate in candidates) {
      final parsed = DoctorProfileFields.tryFromJson(
        candidate,
        fallbackUserId: fallbackUserId,
      );
      if (parsed == null) continue;
      best = best?.mergePreferringNonEmpty(parsed) ?? parsed;
      if (best.hospitalName.trim().isNotEmpty &&
          best.doctorSpeciality.trim().isNotEmpty &&
          best.pmdcNumber.trim().isNotEmpty) {
        break;
      }
    }
    return best;
  }

  static String? _extractUserId(dynamic data) {
    if (data is! Map) return null;
    final m = Map<String, dynamic>.from(data);
    final inner = m['data'] ?? m['Data'] ?? m['result'] ?? m['Result'];
    if (inner is Map) {
      final id = _readString(Map<String, dynamic>.from(inner), 'userId', 'UserId');
      if (id != null && id.isNotEmpty) return id;
    }
    return _readString(m, 'userId', 'UserId');
  }

  static bool? _extractIsVerified(dynamic data) {
    if (data is! Map) return null;
    final m = Map<String, dynamic>.from(data);
    final inner = m['data'] ?? m['Data'] ?? m['result'] ?? m['Result'];
    if (inner is Map) {
      final v = _readBool(Map<String, dynamic>.from(inner), 'isVerified', 'IsVerified');
      if (v != null) return v;
    }
    return _readBool(m, 'isVerified', 'IsVerified');
  }

  static String? _extractToken(dynamic data) {
    if (data is String) return data;
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      final token = _readString(m, 'token', 'Token') ??
          _readString(m, 'accessToken', 'AccessToken');
      if (token != null && token.trim().isNotEmpty) return token.trim();

      final inner = m['data'] ?? m['Data'] ?? m['result'] ?? m['Result'];
      if (inner is Map) {
        final im = Map<String, dynamic>.from(inner);
        final token2 = _readString(im, 'token', 'Token') ??
            _readString(im, 'accessToken', 'AccessToken');
        if (token2 != null && token2.trim().isNotEmpty) return token2.trim();
      }
    }
    return null;
  }

  static String? _extractRefreshToken(dynamic data) {
    if (data is! Map) return null;
    final m = Map<String, dynamic>.from(data);
    final rt = _readString(m, 'refreshToken', 'RefreshToken');
    if (rt != null && rt.trim().isNotEmpty) return rt.trim();

    final inner = m['data'] ?? m['Data'] ?? m['result'] ?? m['Result'];
    if (inner is Map) {
      final rt2 = _readString(
        Map<String, dynamic>.from(inner),
        'refreshToken',
        'RefreshToken',
      );
      if (rt2 != null && rt2.trim().isNotEmpty) return rt2.trim();
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> m, String a, String b) {
    final v = m[a] ?? m[b];
    if (v == null) return null;
    return v.toString();
  }

  static bool? _readBool(Map<String, dynamic> m, String a, String b) {
    final v = m[a] ?? m[b];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
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
