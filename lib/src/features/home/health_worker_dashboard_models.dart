// DTOs aligned with MedicalApi Models/HealthworkerModels (JSON camelCase).
class HwDashboardStats {
  const HwDashboardStats({
    required this.totalPatients,
    required this.patientsToday,
    required this.patientsYesterday,
    required this.pendingFollowUps,
    required this.visitsThisMonth,
    required this.monthlyTarget,
    required this.dailyDifference,
  });

  final int totalPatients;
  final int patientsToday;
  final int patientsYesterday;
  final int pendingFollowUps;
  final int visitsThisMonth;
  final int monthlyTarget;
  final int dailyDifference;

  static HwDashboardStats? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final today = _readInt(m, 'patientsToday', 'PatientsToday') ?? 0;
    final yesterday = _readInt(m, 'patientsYesterday', 'PatientsYesterday') ?? 0;
    final diff = _readInt(m, 'dailyDifference', 'DailyDifference') ?? (today - yesterday);
    return HwDashboardStats(
      totalPatients: _readInt(m, 'totalPatients', 'TotalPatients') ?? 0,
      patientsToday: today,
      patientsYesterday: yesterday,
      pendingFollowUps: _readInt(m, 'pendingFollowUps', 'PendingFollowUps') ?? 0,
      visitsThisMonth: _readInt(m, 'visitsThisMonth', 'VisitsThisMonth') ?? 0,
      monthlyTarget: _readInt(m, 'monthlyTarget', 'MonthlyTarget') ?? 0,
      dailyDifference: diff,
    );
  }
}

class HwFollowUpPatient {
  const HwFollowUpPatient({
    required this.patientId,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.formattedPatientId,
    required this.lastVisitId,
    required this.lastVisitDate,
    this.lastVisitReason,
    this.systolicBP1,
    this.diastolicBP1,
    required this.nextVisitDate,
    required this.isOverdue,
    required this.primaryCondition,
    required this.initials,
  });

  final String patientId;
  final String fullName;
  final int age;
  final String gender;
  final String formattedPatientId;
  final String lastVisitId;
  final DateTime lastVisitDate;
  final String? lastVisitReason;
  final int? systolicBP1;
  final int? diastolicBP1;
  final DateTime nextVisitDate;
  final bool isOverdue;
  final String primaryCondition;
  final String initials;

  String get displayId {
    final f = formattedPatientId.trim();
    return f.isNotEmpty ? f : patientId;
  }

  static HwFollowUpPatient? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final lastVisit = _readDateTime(m, 'lastVisitDate', 'LastVisitDate');
    final nextVisit = _readDateTime(m, 'nextVisitDate', 'NextVisitDate');
    if (lastVisit == null || nextVisit == null) return null;

    return HwFollowUpPatient(
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      fullName: _readString(m, 'fullName', 'FullName') ?? '',
      age: _readInt(m, 'age', 'Age') ?? 0,
      gender: _readString(m, 'gender', 'Gender') ?? '',
      formattedPatientId: _readString(m, 'formattedPatientId', 'FormattedPatientId') ?? '',
      lastVisitId: _readString(m, 'lastVisitId', 'LastVisitId') ?? '',
      lastVisitDate: lastVisit,
      lastVisitReason: _readString(m, 'lastVisitReason', 'LastVisitReason'),
      systolicBP1: _readInt(m, 'systolicBP1', 'SystolicBP1'),
      diastolicBP1: _readInt(m, 'diastolicBP1', 'DiastolicBP1'),
      nextVisitDate: nextVisit,
      isOverdue: _readBool(m, 'isOverdue', 'IsOverdue') ?? false,
      primaryCondition: _readString(m, 'primaryCondition', 'PrimaryCondition') ?? '',
      initials: _readString(m, 'initials', 'Initials') ??
          NameInitialsCompat.fromFullName(_readString(m, 'fullName', 'FullName') ?? ''),
    );
  }
}

class HwPatientSummary {
  const HwPatientSummary({
    required this.patientId,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.formattedPatientId,
    this.cnic,
    required this.primaryCondition,
    required this.lastVisitDate,
    required this.initials,
  });

  final String patientId;
  final String fullName;
  final int age;
  final String gender;
  final String formattedPatientId;
  /// Masked CNIC when API sends it; used for directory search.
  final String? cnic;
  final String primaryCondition;
  final DateTime? lastVisitDate;
  final String initials;

  String get displayId {
    final f = formattedPatientId.trim();
    return f.isNotEmpty ? f : patientId;
  }

  static HwPatientSummary? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final cnicRaw = _readString(m, 'cnic', 'Cnic')?.trim();
    return HwPatientSummary(
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      fullName: _readString(m, 'fullName', 'FullName') ?? '',
      age: _readInt(m, 'age', 'Age') ?? 0,
      gender: _readString(m, 'gender', 'Gender') ?? '',
      formattedPatientId: _readString(m, 'formattedPatientId', 'FormattedPatientId') ?? '',
      cnic: (cnicRaw == null || cnicRaw.isEmpty) ? null : cnicRaw,
      primaryCondition: _readString(m, 'primaryCondition', 'PrimaryCondition') ?? '',
      lastVisitDate: _readDateTime(m, 'lastVisitDate', 'LastVisitDate'),
      initials: _readString(m, 'initials', 'Initials') ??
          NameInitialsCompat.fromFullName(_readString(m, 'fullName', 'FullName') ?? ''),
    );
  }
}

class NameInitialsCompat {
  const NameInitialsCompat._();

  static String fromFullName(String fullName) {
    final t = fullName.trim();
    if (t.isEmpty) return 'U';
    final parts = t.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final c = parts[0][0];
      return c.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

int? _readInt(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

bool? _readBool(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is bool) return v;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  return null;
}

String? _readString(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v == null) return null;
  return v.toString();
}

DateTime? _readDateTime(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v.trim());
  return null;
}
