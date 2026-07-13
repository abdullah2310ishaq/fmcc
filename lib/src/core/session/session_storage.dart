import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:doctor_app/src/core/session/app_session.dart';

class SessionStorage {
  static const _kRole = 'session.role';
  static const _kSignedIn = 'session.signedIn';
  static const _kApproval = 'session.approval';
  static const _kFullName = 'session.fullName';
  static const _kPhone = 'session.phone';
  static const _kEmail = 'session.email';
  static const _kShowDeclinedOnce = 'session.showDeclinedOnce';
  static const _kUserId = 'session.userId';
  static const _kHealthWorkerId = 'session.healthWorkerId';
  static const _kDoctorId = 'session.doctorId';
  static const _kDoctorSpeciality = 'session.doctorSpeciality';
  static const _kPmdcNumber = 'session.pmdcNumber';
  static const _kHospitalName = 'session.hospitalName';
  static const _kHospitalConfirmed = 'session.hospitalConfirmed';

  static const _kAccessToken = 'session.accessToken';
  static const _kRefreshToken = 'session.refreshToken';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  Future<AppSession> read() async {
    final prefs = await SharedPreferences.getInstance();

    final role = _readRole(prefs.getString(_kRole));
    final approval = _readApproval(prefs.getString(_kApproval));
    final isSignedIn = prefs.getBool(_kSignedIn) ?? false;

    // Logged-out cold starts always begin at the role picker — do not restore
    // a stale persisted role from a previous session.
    if (!isSignedIn && role != UserRole.unknown) {
      await prefs.setString(_kRole, _writeRole(UserRole.unknown));
    }
    final effectiveRole = isSignedIn ? role : UserRole.unknown;

    final fullName = prefs.getString(_kFullName) ?? '';
    final phone = prefs.getString(_kPhone) ?? '';
    final email = prefs.getString(_kEmail) ?? '';
    final showDeclinedOnce = prefs.getBool(_kShowDeclinedOnce) ?? false;
    final userId = prefs.getString(_kUserId);
    final healthWorkerId = prefs.getString(_kHealthWorkerId);
    final doctorId = prefs.getString(_kDoctorId);
    final doctorSpeciality = prefs.getString(_kDoctorSpeciality);
    final pmdcNumber = prefs.getString(_kPmdcNumber);
    final hospitalName = prefs.getString(_kHospitalName);
    final hospitalConfirmed = prefs.getBool(_kHospitalConfirmed) ?? false;
    final accessToken = await _secure.read(key: _kAccessToken);
    final refreshToken = await _secure.read(key: _kRefreshToken);

    return AppSession(
      role: effectiveRole,
      isSignedIn: isSignedIn,
      approvalStatus: approval,
      registrationDetails:
          RegistrationDetails(fullName: fullName, phone: phone, email: email),
      showDeclinedMessageOnce: showDeclinedOnce,
      userId: userId,
      healthWorkerId: healthWorkerId,
      doctorId: doctorId,
      doctorSpeciality: doctorSpeciality,
      pmdcNumber: pmdcNumber,
      hospitalName: hospitalName,
      hospitalConfirmed: hospitalConfirmed,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> write(AppSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, _writeRole(session.role));
    await prefs.setBool(_kSignedIn, session.isSignedIn);
    await prefs.setString(_kApproval, _writeApproval(session.approvalStatus));
    await prefs.setString(_kFullName, session.registrationDetails.fullName);
    await prefs.setString(_kPhone, session.registrationDetails.phone);
    await prefs.setString(_kEmail, session.registrationDetails.email);
    await prefs.setBool(_kShowDeclinedOnce, session.showDeclinedMessageOnce);
    await prefs.setBool(_kHospitalConfirmed, session.hospitalConfirmed);

    if (session.userId == null) {
      await prefs.remove(_kUserId);
    } else {
      await prefs.setString(_kUserId, session.userId!);
    }

    if (session.healthWorkerId == null ||
        session.healthWorkerId!.trim().isEmpty) {
      await prefs.remove(_kHealthWorkerId);
    } else {
      await prefs.setString(_kHealthWorkerId, session.healthWorkerId!.trim());
    }

    await _writeOptionalString(prefs, _kDoctorId, session.doctorId);
    await _writeOptionalString(
      prefs,
      _kDoctorSpeciality,
      session.doctorSpeciality,
    );
    await _writeOptionalString(prefs, _kPmdcNumber, session.pmdcNumber);
    await _writeOptionalString(prefs, _kHospitalName, session.hospitalName);

    if (session.accessToken == null || session.accessToken!.trim().isEmpty) {
      await _secure.delete(key: _kAccessToken);
    } else {
      await _secure.write(key: _kAccessToken, value: session.accessToken);
    }

    if (session.refreshToken == null || session.refreshToken!.trim().isEmpty) {
      await _secure.delete(key: _kRefreshToken);
    } else {
      await _secure.write(key: _kRefreshToken, value: session.refreshToken);
    }
  }

  Future<void> clearAuthOnly({required bool keepRole}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!keepRole) {
      await prefs.remove(_kRole);
    }
    await prefs.remove(_kSignedIn);
    await prefs.remove(_kApproval);
    await prefs.remove(_kFullName);
    await prefs.remove(_kPhone);
    await prefs.remove(_kEmail);
    await prefs.remove(_kShowDeclinedOnce);
    await prefs.remove(_kUserId);
    await prefs.remove(_kHealthWorkerId);
    await prefs.remove(_kDoctorId);
    await prefs.remove(_kDoctorSpeciality);
    await prefs.remove(_kPmdcNumber);
    await prefs.remove(_kHospitalName);
    await prefs.remove(_kHospitalConfirmed);
    await _secure.delete(key: _kAccessToken);
    await _secure.delete(key: _kRefreshToken);
  }

  static Future<void> _writeOptionalString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value.trim());
    }
  }

  static UserRole _readRole(String? raw) {
    switch (raw) {
      case 'lhw':
        return UserRole.ladyHealthWorker;
      case 'doctor':
        return UserRole.doctor;
      default:
        return UserRole.unknown;
    }
  }

  static String _writeRole(UserRole role) {
    switch (role) {
      case UserRole.ladyHealthWorker:
        return 'lhw';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.unknown:
        return 'unknown';
    }
  }

  static ApprovalStatus _readApproval(String? raw) {
    switch (raw) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'approved':
        return ApprovalStatus.approved;
      case 'declined':
        return ApprovalStatus.declined;
      default:
        return ApprovalStatus.none;
    }
  }

  static String _writeApproval(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return 'pending';
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.declined:
        return 'declined';
      case ApprovalStatus.none:
        return 'none';
    }
  }
}
