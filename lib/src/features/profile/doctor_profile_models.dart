import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

/// `GET /api/Profile/doctor-profile/{userId}` — `DoctorProfileViewModel`.
class DoctorProfile {
  const DoctorProfile({
    required this.userId,
    required this.doctorId,
    required this.specialtyName,
    required this.pmdcNumber,
    required this.hospitalName,
    required this.isVerified,
  });

  final String userId;
  final String doctorId;
  final String specialtyName;
  final String pmdcNumber;
  final String hospitalName;
  final bool isVerified;

  DoctorProfileFields toProfileFields() {
    return DoctorProfileFields(
      doctorSpeciality: specialtyName,
      pmdcNumber: pmdcNumber,
      hospitalName: hospitalName,
      doctorId: doctorId.isNotEmpty ? doctorId : userId,
    );
  }

  static DoctorProfile? tryFromApi(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final inner = m['data'] ?? m['Data'] ?? m['result'] ?? m['Result'];
    if (inner is Map) {
      final parsed = _fromMap(Map<String, dynamic>.from(inner));
      if (parsed != null) return parsed;
    }
    return _fromMap(m);
  }

  static DoctorProfile? _fromMap(Map<String, dynamic> m) {
    final userId = _readString(m, 'userId', 'UserId');
    if (userId == null || userId.isEmpty) return null;

    final doctorId = _readString(m, 'doctorId', 'DoctorId') ?? userId;
    final specialty = _readString(m, 'specialtyName', 'SpecialtyName') ??
        _readString(m, 'doctorSpeciality', 'DoctorSpeciality') ??
        '';
    final pmdc = _readString(m, 'pmdcNumber', 'PMDCNumber') ?? '';

    var hospital = _readString(m, 'hospitalName', 'HospitalName') ?? '';
    if (hospital.trim().isEmpty) {
      final district = _readString(m, 'districtName', 'DistrictName') ?? '';
      final province = _readString(m, 'provinceName', 'ProvinceName') ?? '';
      final parts = [district.trim(), province.trim()]
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) hospital = parts.join(', ');
    }

    return DoctorProfile(
      userId: userId,
      doctorId: doctorId,
      specialtyName: specialty.trim(),
      pmdcNumber: pmdc.trim(),
      hospitalName: hospital.trim(),
      isVerified: _readBool(m, 'isVerified', 'IsVerified') ?? false,
    );
  }
}

String? _readString(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v == null) return null;
  return v.toString();
}

bool? _readBool(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is bool) return v;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return null;
}
