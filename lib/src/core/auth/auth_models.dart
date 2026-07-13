import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.isVerified,
    this.refreshToken,
    this.doctorProfile,
    this.rawDataWasNull = false,
  });

  final String accessToken;
  final String userId;
  final bool isVerified;
  final String? refreshToken;

  /// Doctor-specific fields when RoleId = 1 and profile data is present.
  final DoctorProfileFields? doctorProfile;

  /// True when the API returned an explicit null/empty profile payload.
  final bool rawDataWasNull;
}

/// In-memory doctor login awaiting hospital confirmation (not persisted).
class PendingDoctorLogin {
  const PendingDoctorLogin({
    required this.accessToken,
    required this.userId,
    this.refreshToken,
    required this.doctorSpeciality,
    required this.pmdcNumber,
    required this.hospitalName,
    this.doctorId,
  });

  final String accessToken;
  final String userId;
  final String? refreshToken;
  final String doctorSpeciality;
  final String pmdcNumber;
  final String hospitalName;
  final String? doctorId;

  String get resolvedDoctorId {
    final d = doctorId?.trim();
    if (d != null && d.isNotEmpty) return d;
    return userId;
  }
}
