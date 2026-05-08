import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:doctor_app/src/core/session/app_session.dart';

class SessionStorage {
  static const _kRole = 'session.role';
  static const _kSignedIn = 'session.signedIn';
  static const _kApproval = 'session.approval';
  static const _kFullName = 'session.fullName';
  static const _kPhone = 'session.phone';
  static const _kShowDeclinedOnce = 'session.showDeclinedOnce';
  static const _kUserId = 'session.userId';

  static const _kAccessToken = 'session.accessToken';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  Future<AppSession> read() async {
    final prefs = await SharedPreferences.getInstance();

    final role = _readRole(prefs.getString(_kRole));
    final approval = _readApproval(prefs.getString(_kApproval));
    final isSignedIn = prefs.getBool(_kSignedIn) ?? false;

    final fullName = prefs.getString(_kFullName) ?? '';
    final phone = prefs.getString(_kPhone) ?? '';
    final showDeclinedOnce = prefs.getBool(_kShowDeclinedOnce) ?? false;
    final userId = prefs.getString(_kUserId);
    final accessToken = await _secure.read(key: _kAccessToken);

    return AppSession(
      role: role,
      isSignedIn: isSignedIn,
      approvalStatus: approval,
      registrationDetails: RegistrationDetails(fullName: fullName, phone: phone),
      showDeclinedMessageOnce: showDeclinedOnce,
      userId: userId,
      accessToken: accessToken,
    );
  }

  Future<void> write(AppSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, _writeRole(session.role));
    await prefs.setBool(_kSignedIn, session.isSignedIn);
    await prefs.setString(_kApproval, _writeApproval(session.approvalStatus));
    await prefs.setString(_kFullName, session.registrationDetails.fullName);
    await prefs.setString(_kPhone, session.registrationDetails.phone);
    await prefs.setBool(_kShowDeclinedOnce, session.showDeclinedMessageOnce);
    if (session.userId == null) {
      await prefs.remove(_kUserId);
    } else {
      await prefs.setString(_kUserId, session.userId!);
    }

    if (session.accessToken == null || session.accessToken!.trim().isEmpty) {
      await _secure.delete(key: _kAccessToken);
    } else {
      await _secure.write(key: _kAccessToken, value: session.accessToken);
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
    await prefs.remove(_kShowDeclinedOnce);
    await prefs.remove(_kUserId);
    await _secure.delete(key: _kAccessToken);
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

