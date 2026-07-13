import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

/// `GET /api/Doctor/{doctorId}` — full doctor profile for the workspace.
class DoctorProfile {
  const DoctorProfile({
    required this.userId,
    required this.doctorId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.specialtyName,
    required this.pmdcNumber,
    required this.hospitalName,
    required this.isVerified,
    this.gender = '',
    this.cnic = '',
    this.feePerPatient,
    this.joinedDate,
    this.provinceName = '',
    this.districtName = '',
    this.tehsilName = '',
    this.profileImageUrl = '',
  });

  final String userId;
  final String doctorId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String specialtyName;
  final String pmdcNumber;
  final String hospitalName;
  final bool isVerified;
  final String gender;
  final String cnic;
  final double? feePerPatient;
  final DateTime? joinedDate;
  final String provinceName;
  final String districtName;
  final String tehsilName;
  final String profileImageUrl;

  String get fullName => '$firstName $lastName'.trim();

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
    final userId = _readString(m, 'userId', 'UserId') ?? '';
    final doctorId = _readString(m, 'doctorId', 'DoctorId') ??
        _readString(m, 'professionalId', 'ProfessionalId') ??
        userId;
    if (doctorId.trim().isEmpty && userId.trim().isEmpty) return null;

    final specialty = _readString(m, 'specialtyName', 'SpecialtyName') ??
        _readString(m, 'doctorSpeciality', 'DoctorSpeciality') ??
        '';
    final pmdc = _readString(m, 'pmdcNumber', 'PMDCNumber') ?? '';

    var hospital = _readString(m, 'hospitalName', 'HospitalName') ?? '';
    final district = _readString(m, 'districtName', 'DistrictName') ?? '';
    final province = _readString(m, 'provinceName', 'ProvinceName') ?? '';
    final tehsil = _readString(m, 'tehsilName', 'TehsilName') ?? '';
    if (hospital.trim().isEmpty) {
      final parts = [district.trim(), province.trim()]
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) hospital = parts.join(', ');
    }

    var firstName = _readString(m, 'firstName', 'FirstName') ?? '';
    var lastName = _readString(m, 'lastName', 'LastName') ?? '';
    if (firstName.trim().isEmpty && lastName.trim().isEmpty) {
      final combined = _readString(m, 'fullName', 'FullName') ??
          _readString(m, 'name', 'Name') ??
          _readString(m, 'doctorName', 'DoctorName') ??
          '';
      final parts = combined.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        firstName = parts.first;
        if (parts.length > 1) {
          lastName = parts.sublist(1).join(' ');
        }
      }
    }

    return DoctorProfile(
      userId: userId.isNotEmpty ? userId : doctorId,
      doctorId: doctorId,
      firstName: firstName,
      lastName: lastName,
      email: _readString(m, 'email', 'Email') ?? '',
      phoneNumber: _readString(m, 'phoneNumber', 'PhoneNumber') ?? '',
      specialtyName: specialty.trim(),
      pmdcNumber: pmdc.trim(),
      hospitalName: hospital.trim(),
      isVerified: _readBool(m, 'isVerified', 'IsVerified') ?? false,
      gender: _readString(m, 'gender', 'Gender') ?? '',
      cnic: _readString(m, 'cnic', 'CNIC') ?? '',
      feePerPatient: _readDouble(m, 'feePerPatient', 'FeePerPatient'),
      joinedDate: _readDate(m, 'joinedDate', 'JoinedDate') ??
          _readDate(m, 'createdAt', 'CreatedAt'),
      provinceName: province.trim(),
      districtName: district.trim(),
      tehsilName: tehsil.trim(),
      profileImageUrl:
          _readString(m, 'profileImageUrl', 'ProfileImageUrl') ?? '',
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

double? _readDouble(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

DateTime? _readDate(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is DateTime) return v;
  if (v is String && v.trim().isNotEmpty) {
    return DateTime.tryParse(v.trim());
  }
  return null;
}
