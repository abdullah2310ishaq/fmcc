import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/auth/auth_api.dart';
import 'package:doctor_app/src/core/auth/auth_models.dart';
import 'package:doctor_app/src/core/auth/jwt_utils.dart';
import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/network/session_auth_hooks.dart';
import 'package:doctor_app/src/core/reference/reference_api.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/core/roles/role_ids.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_storage.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/profile/doctor_profile_models.dart';
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
    _doctorApi = DoctorApi(_apiClient);
  }

  final SessionStorage _storage;
  late final ApiClient _apiClient;
  late final AuthApi _authApi;
  late final ProfileApi _profileApi;
  late final ReferenceApi _referenceApi;
  late final DoctorApi _doctorApi;
  AppSession _state;

  /// Held until the doctor confirms hospital assignment (not persisted).
  PendingDoctorLogin? _pendingDoctorLogin;

  AppSession get state => _state;

  PendingDoctorLogin? get pendingDoctorLogin => _pendingDoctorLogin;

  bool get hasPendingDoctorHospitalConfirmation =>
      _pendingDoctorLogin != null;

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

  RegistrationDetails _registrationFromGoogleToken(
    String idToken, {
    RegistrationDetails? base,
  }) {
    final claims = JwtUtils.tryDecodePayload(idToken);
    final email = (claims['email'] ??
            claims['Email'] ??
            claims['preferred_username'] ??
            '')
        .toString()
        .trim();
    final name = (claims['name'] ??
            claims['Name'] ??
            claims['given_name'] ??
            claims['givenName'] ??
            '')
        .toString()
        .trim();
    final current = base ?? _state.registrationDetails;
    return current.copyWith(
      fullName:
          current.fullName.trim().isNotEmpty ? current.fullName : name,
      email: current.email.trim().isNotEmpty ? current.email : email,
    );
  }

  Future<DoctorProfileFields?> _loadDoctorProfileFields({
    required String doctorId,
    required String bearerToken,
  }) async {
    try {
      final profile = await _doctorApi.getDoctor(
        doctorId: doctorId,
        bearerToken: bearerToken,
      );
      return profile?.toProfileFields();
    } catch (e, st) {
      AppLogger.instance.w(
        '[AUTH] doctor profile prefetch failed doctorId=$doctorId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
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

      // Doctor: hold tokens until hospital confirmation — do not finalize session yet.
      if (_state.role == UserRole.doctor) {
        final googleDetails = _registrationFromGoogleToken(idToken);
        var profile = session.doctorProfile;

        // Prefer login HospitalName; fill gaps from GET /api/Doctor/{id}.
        final fromApi = await _loadDoctorProfileFields(
          doctorId: profile?.doctorId?.trim().isNotEmpty == true
              ? profile!.doctorId!.trim()
              : session.userId,
          bearerToken: session.accessToken,
        );
        profile = (profile ??
                DoctorProfileFields(
                  doctorSpeciality: '',
                  pmdcNumber: '',
                  hospitalName: '',
                  doctorId: session.userId,
                ))
            .mergePreferringNonEmpty(fromApi);

        _pendingDoctorLogin = PendingDoctorLogin(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          userId: session.userId,
          doctorSpeciality: profile.doctorSpeciality,
          pmdcNumber: profile.pmdcNumber,
          hospitalName: profile.hospitalName,
          doctorId: profile.doctorId,
        );
        await _setState(
          _state.copyWith(
            // Keep Google identity for profile display even before confirm.
            registrationDetails: googleDetails,
            hospitalName: profile.hospitalName.isNotEmpty
                ? profile.hospitalName
                : _state.hospitalName,
            doctorSpeciality: profile.doctorSpeciality.isNotEmpty
                ? profile.doctorSpeciality
                : _state.doctorSpeciality,
            pmdcNumber: profile.pmdcNumber.isNotEmpty
                ? profile.pmdcNumber
                : _state.pmdcNumber,
          ),
        );
        AppLogger.instance.i(
          '[AUTH] doctor google-login OK userId=${session.userId} '
          'hospital=${profile.hospitalName} name=${googleDetails.fullName} '
          'email=${googleDetails.email} awaiting hospital confirmation',
        );
        return;
      }

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
          registrationDetails: _registrationFromGoogleToken(
            idToken,
            base: nextDetails ?? _state.registrationDetails,
          ),
          hospitalConfirmed: false,
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
          'method=${e.requestOptions.method} role=${_state.role} '
          'roleId=${RoleIds.fromRole(_state.role)} '
          'responseData=$data message=${e.message}',
          error: e,
          stackTrace: st,
        );
        if (_state.role == UserRole.doctor && status == 401) {
          throw const ValidationFailure(AuthApi.doctorNotVerifiedMessage);
        }
      } else if (e is ApiFailure) {
        AppLogger.instance.e(
          '[AUTH] google-login blocked: ${e.message}',
          error: e,
          stackTrace: st,
        );
        rethrow;
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

  /// Doctor confirmed they still work at the hospital — complete login.
  Future<void> confirmDoctorHospital() async {
    final pending = _pendingDoctorLogin;
    if (pending == null) {
      throw const ValidationFailure('No pending doctor login to confirm.');
    }
    _pendingDoctorLogin = null;
    final googleName = _state.registrationDetails.fullName.trim();
    final googleEmail = _state.registrationDetails.email.trim();
    await _setState(
      _state.copyWith(
        isSignedIn: true,
        approvalStatus: ApprovalStatus.approved,
        showDeclinedMessageOnce: false,
        userId: pending.userId,
        doctorId: pending.resolvedDoctorId,
        doctorSpeciality: pending.doctorSpeciality,
        pmdcNumber: pending.pmdcNumber,
        hospitalName: pending.hospitalName,
        hospitalConfirmed: true,
        accessToken: pending.accessToken,
        refreshToken: pending.refreshToken,
        registrationDetails: _state.registrationDetails.copyWith(
          fullName: googleName.isNotEmpty ? googleName : 'Doctor',
          email: googleEmail,
          phone: _state.registrationDetails.phone.trim().isNotEmpty
              ? _state.registrationDetails.phone
              : '—',
        ),
      ),
    );
    AppLogger.instance.i(
      '[AUTH] doctor hospital confirmed doctorId=${pending.resolvedDoctorId}',
    );
  }

  /// Doctor said they no longer work at the hospital — unassign only.
  /// Pending login stays until [LogoutFlow] so the confirmation route remains
  /// under the unassigned message sheet.
  Future<void> declineDoctorHospital() async {
    final pending = _pendingDoctorLogin;
    if (pending == null) return;

    try {
      await _doctorApi.unassignHospital(
        doctorId: pending.resolvedDoctorId,
        bearerToken: pending.accessToken,
      );
    } catch (e, st) {
      AppLogger.instance.e(
        '[AUTH] doctor unassign-hospital failed',
        error: e,
        stackTrace: st,
      );
      // Still abort login even if unassign fails.
    }

    AppLogger.instance.i(
      '[AUTH] doctor hospital declined; awaiting OK → logout to role',
    );
  }

  Future<void> clearPendingDoctorLogin() async {
    if (_pendingDoctorLogin == null) return;
    _pendingDoctorLogin = null;
    notifyListeners();
  }

  Future<void> logout({bool keepRole = true}) async {
    _pendingDoctorLogin = null;
    final next = _state.copyWith(
      isSignedIn: false,
      approvalStatus: ApprovalStatus.none,
      registrationDetails: const RegistrationDetails(fullName: '', phone: '', email: ''),
      showDeclinedMessageOnce: false,
      userId: null,
      healthWorkerId: null,
      doctorId: null,
      doctorSpeciality: null,
      pmdcNumber: null,
      hospitalName: null,
      hospitalConfirmed: false,
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

  Future<DoctorProfile?> fetchDoctorProfile() async {
    final token = _state.accessToken?.trim();
    final doctorId = _state.doctorIdForApis.trim();
    if (token == null || token.isEmpty || doctorId.isEmpty) {
      return null;
    }
    try {
      return await _doctorApi.getDoctor(
        doctorId: doctorId,
        bearerToken: token,
      );
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  /// Cold-start doctor sessions may lack the backend `doctorId` used by queue/dashboard APIs.
  Future<void> hydrateDoctorProfileIfNeeded() async {
    if (_state.role != UserRole.doctor) return;
    if (!_state.isSignedIn) return;
    if (!_state.hospitalConfirmed) return;

    final token = _state.accessToken?.trim();
    final doctorId = _state.doctorIdForApis.trim();
    if (token == null || token.isEmpty || doctorId.isEmpty) {
      return;
    }

    final existingDoctorId = _state.doctorId?.trim();
    if (existingDoctorId != null &&
        existingDoctorId.isNotEmpty &&
        existingDoctorId != _state.userId?.trim()) {
      return;
    }

    try {
      final profile = await _doctorApi.getDoctor(
        doctorId: doctorId,
        bearerToken: token,
      );
      if (profile == null) return;

      final fields = profile.toProfileFields();
      final nextDoctorId = fields.doctorId?.trim();
      if (nextDoctorId == null || nextDoctorId.isEmpty) return;

      final apiName = profile.fullName;
      final apiEmail = profile.email.trim();
      final apiPhone = profile.phoneNumber.trim();

      await _setState(
        _state.copyWith(
          doctorId: nextDoctorId,
          doctorSpeciality: fields.doctorSpeciality.isNotEmpty
              ? fields.doctorSpeciality
              : _state.doctorSpeciality,
          pmdcNumber:
              fields.pmdcNumber.isNotEmpty ? fields.pmdcNumber : _state.pmdcNumber,
          hospitalName: fields.hospitalName.isNotEmpty
              ? fields.hospitalName
              : _state.hospitalName,
          registrationDetails: _state.registrationDetails.copyWith(
            fullName: apiName.isNotEmpty
                ? apiName
                : _state.registrationDetails.fullName,
            email: apiEmail.isNotEmpty
                ? apiEmail
                : _state.registrationDetails.email,
            phone: apiPhone.isNotEmpty
                ? apiPhone
                : _state.registrationDetails.phone,
          ),
        ),
      );
      AppLogger.instance.i(
        '[AUTH] hydrated doctor profile doctorId=$nextDoctorId',
      );
    } catch (e, st) {
      AppLogger.instance.w(
        '[AUTH] doctor profile hydrate failed doctorId=$doctorId',
        error: e,
        stackTrace: st,
      );
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
    _pendingDoctorLogin = null;
    final next = _state.copyWith(
      isSignedIn: false,
      approvalStatus: ApprovalStatus.none,
      registrationDetails: const RegistrationDetails(fullName: '', phone: '', email: ''),
      showDeclinedMessageOnce: true,
      userId: null,
      healthWorkerId: null,
      doctorId: null,
      doctorSpeciality: null,
      pmdcNumber: null,
      hospitalName: null,
      hospitalConfirmed: false,
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
