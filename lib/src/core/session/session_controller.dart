import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/auth/auth_api.dart';
import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/reference/reference_api.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_storage.dart';
import 'package:doctor_app/src/features/profile/health_worker_profile_models.dart';
import 'package:doctor_app/src/features/profile/profile_api.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required AppSession initialState,
    required SessionStorage storage,
    ApiClient? apiClient,
  })  : _state = initialState,
        _storage = storage,
        _apiClient = (apiClient ?? ApiClient()) {
    _authApi = AuthApi(_apiClient);
    _profileApi = ProfileApi(_apiClient);
    _referenceApi = ReferenceApi(_apiClient);
  }

  final SessionStorage _storage;
  final ApiClient _apiClient;
  late final AuthApi _authApi;
  late final ProfileApi _profileApi;
  late final ReferenceApi _referenceApi;
  AppSession _state;

  AppSession get state => _state;

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
      if (approval == ApprovalStatus.approved) {
        try {
          final existing = await _profileApi.getHealthWorkerProfile(
            userId: session.userId,
            bearerToken: session.accessToken,
          );
          if (existing != null) {
            final fullName = '${existing.firstName} ${existing.lastName}'.trim();
            final phone = existing.phoneNumber.trim();
            if (fullName.isNotEmpty && phone.isNotEmpty) {
              nextDetails = _state.registrationDetails.copyWith(
                fullName: fullName,
                phone: phone,
              );
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
          accessToken: session.accessToken,
          registrationDetails: nextDetails ?? _state.registrationDetails,
        ),
      );
    } catch (e) {
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
      accessToken: null,
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

      final fullName = '${profile.firstName} ${profile.lastName}'.trim();
      await _setState(
        _state.copyWith(
          registrationDetails: _state.registrationDetails.copyWith(
            fullName: fullName,
            phone: profile.phoneNumber,
          ),
        ),
      );
    } catch (e) {
      throw _apiClient.mapError(e);
    }
  }

  Future<HealthWorkerProfile?> fetchHealthWorkerProfile() async {
    final token = _state.accessToken;
    final userId = _state.userId;
    if (token == null || token.trim().isEmpty || userId == null || userId.isEmpty) {
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

