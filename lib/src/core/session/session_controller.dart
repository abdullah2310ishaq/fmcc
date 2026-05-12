import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/auth/auth_api.dart';
import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/network/session_auth_hooks.dart';
import 'package:doctor_app/src/core/reference/reference_api.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_storage.dart';
import 'package:doctor_app/src/features/profile/health_worker_profile_models.dart';
import 'package:doctor_app/src/features/profile/profile_api.dart';

class SessionController extends ChangeNotifier implements SessionAuthHooks {
  SessionController({
    required AppSession initialState,
    required SessionStorage storage,
    ApiClient? apiClient,
  })  : _state = initialState,
        _storage = storage {
    _apiClient = apiClient ?? ApiClient(authHooks: this);
    _authApi = AuthApi(_apiClient);
    _profileApi = ProfileApi(_apiClient);
    _referenceApi = ReferenceApi(_apiClient);
  }

  final SessionStorage _storage;
  late final ApiClient _apiClient;
  late final AuthApi _authApi;
  late final ProfileApi _profileApi;
  late final ReferenceApi _referenceApi;
  AppSession _state;

  AppSession get state => _state;

  /// Shared HTTP client (auth interceptors, refresh). Use for feature `*Api` classes.
  ApiClient get apiClient => _apiClient;

  @override
  String? get accessToken => _state.accessToken;

  @override
  String? get refreshToken => _state.refreshToken;

  Future<bool>? _refreshChain;

  @override
  Future<bool> tryRefreshTokensLocked() {
    return _refreshChain ??=
        _performTokenRefresh().whenComplete(() => _refreshChain = null);
  }

  Future<bool> _performTokenRefresh() async {
    final access = _state.accessToken?.trim();
    final refresh = _state.refreshToken?.trim();
    if (access == null ||
        refresh == null ||
        access.isEmpty ||
        refresh.isEmpty) {
      return false;
    }
    try {
      final session = await _authApi.refreshTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      await _setState(
        _state.copyWith(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken ?? refresh,
          userId: session.userId,
        ),
      );
      return true;
    } catch (e, st) {
      AppLogger.instance.e(
        '[AUTH] Refresh token exchange failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  @override
  Future<void> logoutDueToExpiredSession() => logout(keepRole: true);

  Future<void> _setState(AppSession next) async {
    if (next == _state) return;
    _state = next;
    notifyListeners();
    await _storage.write(_state);
  }

  Future<void> selectRole(UserRole role) async {
    await _setState(_state.copyWith(role: role));
  }

  Future<void> signInWithGoogle({required bool isRegister}) async {
    // NOTE: UI layer handles real Google Sign-In; this method consumes IdToken.
    // For now we accept a debug token via env/fixtures until Google Sign-In is wired.
    throw UnimplementedError(
      'signInWithGoogle needs an IdToken. Use signInWithGoogleIdToken().',
    );
  }

  Future<void> signInWithGoogleIdToken({
    required String idToken,
    required bool isRegister,
  }) async {
    try {
      final session = await _authApi.googleLogin(
        idToken: idToken,
        role: _state.role,
      );

      final approval =
          session.isVerified ? ApprovalStatus.approved : ApprovalStatus.pending;

      // Avoid route flicker: compute final "registration complete" before first notifyListeners().
      RegistrationDetails? nextDetails;
      String? healthWorkerIdFromProfile;
      if (approval == ApprovalStatus.approved) {
        try {
          final existing = await _profileApi.getHealthWorkerProfile(
            userId: session.userId,
            bearerToken: session.accessToken,
          );
          if (existing != null) {
            final fullName =
                '${existing.firstName} ${existing.lastName}'.trim();
            final phone = existing.phoneNumber.trim();
            if (fullName.isNotEmpty && phone.isNotEmpty) {
              nextDetails = _state.registrationDetails.copyWith(
                fullName: fullName,
                phone: phone,
              );
            }
            final hid = existing.healthWorkerId?.trim();
            if (hid != null && hid.isNotEmpty) {
              healthWorkerIdFromProfile = hid;
            }
          }
        } catch (_) {
          // If prefill fails, fallback to current redirect behavior.
        }
      }

      await _setState(
        _state.copyWith(
          isSignedIn: true,
          approvalStatus: approval,
          showDeclinedMessageOnce: false,
          userId: session.userId,
          healthWorkerId: healthWorkerIdFromProfile,
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          registrationDetails: nextDetails ?? _state.registrationDetails,
        ),
      );
      AppLogger.instance.i(
        '[AUTH] google-login OK userId=${session.userId} '
        'healthWorkerId=$healthWorkerIdFromProfile '
        'isVerified=${session.isVerified} approvalStatus=$approval role=${_state.role}',
      );
    } catch (e, st) {
      if (e is DioException) {
        final uri = e.requestOptions.uri;
        final status = e.response?.statusCode;
        final data = e.response?.data;
        AppLogger.instance.e(
          '[AUTH] google-login API error '
          'dioType=${e.type} status=$status uri=$uri '
          'method=${e.requestOptions.method} '
          'responseData=$data message=${e.message}',
          error: e,
          stackTrace: st,
        );
      } else {
        AppLogger.instance.e(
          '[AUTH] google-login unexpected error type=${e.runtimeType}',
          error: e,
          stackTrace: st,
        );
      }
      throw _apiClient.mapError(e);
    }
  }

  Future<void> logout({bool keepRole = true}) async {
    final next = _state.copyWith(
      isSignedIn: false,
      approvalStatus: ApprovalStatus.none,
      registrationDetails: const RegistrationDetails(fullName: '', phone: ''),
      showDeclinedMessageOnce: false,
      userId: null,
      healthWorkerId: null,
      accessToken: null,
      refreshToken: null,
      role: keepRole ? _state.role : UserRole.unknown,
    );
    _state = next;
    notifyListeners();
    await _storage.clearAuthOnly(keepRole: keepRole);
    await _storage.write(_state);
  }

  Future<void> completeRegistrationDetails({
    required HealthWorkerProfileUpsert profile,
  }) async {
    final token = _state.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const UnauthorizedFailure('Unauthorized. Please login again.');
    }

    try {
      await _profileApi.upsertHealthWorkerProfile(
        profile: profile,
        bearerToken: token,
      );

      HealthWorkerProfile? refreshed;
      try {
        refreshed = await _profileApi.getHealthWorkerProfile(
          userId: profile.userId,
          bearerToken: token,
        );
      } catch (_) {}

      final hid = refreshed?.healthWorkerId?.trim();
      final nextHwId =
          (hid != null && hid.isNotEmpty) ? hid : _state.healthWorkerId;

      final fullName = '${profile.firstName} ${profile.lastName}'.trim();
      await _setState(
        _state.copyWith(
          registrationDetails: _state.registrationDetails.copyWith(
            fullName: fullName,
            phone: profile.phoneNumber,
          ),
          healthWorkerId: nextHwId,
        ),
      );
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  Future<HealthWorkerProfile?> fetchHealthWorkerProfile() async {
    final token = _state.accessToken;
    final userId = _state.userId;
    if (token == null ||
        token.trim().isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return null;
    }
    try {
      return await _profileApi.getHealthWorkerProfile(
        userId: userId,
        bearerToken: token,
      );
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  /// Cold-start sessions may have been saved before [AppSession.healthWorkerId] was persisted.
  /// Loads profile once (approved LHW only) so patient list/create use `healthWorkerId`, not account `userId`.
  Future<void> hydrateLhwHealthWorkerIdIfNeeded() async {
    if (_state.role != UserRole.ladyHealthWorker) return;
    if (!_state.isSignedIn) return;
    if (_state.approvalStatus != ApprovalStatus.approved) return;
    final existing = _state.healthWorkerId?.trim();
    if (existing != null && existing.isNotEmpty) return;

    final token = _state.accessToken?.trim();
    final userId = _state.userId?.trim();
    if (token == null ||
        token.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return;
    }
    try {
      final profile = await _profileApi.getHealthWorkerProfile(
        userId: userId,
        bearerToken: token,
      );
      final hid = profile?.healthWorkerId?.trim();
      if (hid == null || hid.isEmpty) return;
      await _setState(_state.copyWith(healthWorkerId: hid));
    } catch (e, st) {
      AppLogger.instance.w(
        '[SESSION] hydrate healthWorkerId failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<List<EducationLevel>> fetchEducationLevels() async {
    final token = _state.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const UnauthorizedFailure('Unauthorized. Please login again.');
    }
    try {
      return await _referenceApi.getEducationLevels(bearerToken: token);
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  Future<List<Province>> fetchProvinces() async {
    final token = _state.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const UnauthorizedFailure('Unauthorized. Please login again.');
    }
    try {
      return await _referenceApi.getProvinces(bearerToken: token);
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  Future<List<District>> fetchDistricts({required int provinceId}) async {
    final token = _state.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const UnauthorizedFailure('Unauthorized. Please login again.');
    }
    try {
      return await _referenceApi.getDistricts(
        provinceId: provinceId,
        bearerToken: token,
      );
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  Future<List<NamedReferenceItem>> fetchMaritalStatuses() async {
    final token = _state.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const UnauthorizedFailure('Unauthorized. Please login again.');
    }
    try {
      return await _referenceApi.getMaritalStatuses(bearerToken: token);
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  Future<List<NamedReferenceItem>> fetchMedicalConditions() async {
    final token = _state.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const UnauthorizedFailure('Unauthorized. Please login again.');
    }
    try {
      return await _referenceApi.getMedicalConditions(bearerToken: token);
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  Future<List<Tehsil>> fetchTehsils({
    required int provinceId,
    required int districtId,
  }) async {
    final token = _state.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const UnauthorizedFailure('Unauthorized. Please login again.');
    }
    try {
      return await _referenceApi.getTehsils(
        provinceId: provinceId,
        districtId: districtId,
        bearerToken: token,
      );
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  /// Called by router on launch if persisted state is declined.
  /// It signs out but keeps a one-time flag to show the declined message.
  Future<void> handleDeclinedOnLaunch() async {
    if (_state.approvalStatus != ApprovalStatus.declined) return;
    final next = _state.copyWith(
      isSignedIn: false,
      approvalStatus: ApprovalStatus.none,
      registrationDetails: const RegistrationDetails(fullName: '', phone: ''),
      showDeclinedMessageOnce: true,
      userId: null,
      accessToken: null,
      refreshToken: null,
    );
    await _setState(next);
  }

  /// Debug helpers (until API integration).
  Future<void> debugApprove() async {
    if (!kDebugMode) return;
    await _setState(_state.copyWith(approvalStatus: ApprovalStatus.approved));
  }

  Future<void> debugDecline() async {
    if (!kDebugMode) return;
    await _setState(_state.copyWith(approvalStatus: ApprovalStatus.declined));
  }

  Future<void> consumeDeclinedMessageFlag() async {
    if (!_state.showDeclinedMessageOnce) return;
    await _setState(_state.copyWith(showDeclinedMessageOnce: false));
  }
}
