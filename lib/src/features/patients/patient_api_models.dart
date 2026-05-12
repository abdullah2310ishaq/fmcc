/// Backend `PatientUpsertResult` (camelCase JSON).
class PatientUpsertResult {
  const PatientUpsertResult({
    required this.id,
    required this.patientNumber,
  });

  final String id;
  final int patientNumber;

  static PatientUpsertResult? tryParse(dynamic root) {
    final m = _unwrapDataMap(root);
    if (m == null) return null;
    final id = _readString(m, 'id', 'Id');
    if (id == null || id.isEmpty) return null;
    return PatientUpsertResult(
      id: id,
      patientNumber: _readInt(m, 'patientNumber', 'PatientNumber') ?? 0,
    );
  }
}

class PatientMedicalHistoryRow {
  const PatientMedicalHistoryRow({
    required this.id,
    required this.patientId,
    required this.conditionId,
    required this.conditionName,
    this.durationInMonths,
    required this.isOnMedication,
    this.complianceLevelId,
    required this.complianceLevelName,
  });

  final int id;
  final String patientId;
  final int conditionId;
  final String conditionName;
  final int? durationInMonths;
  final bool isOnMedication;
  final int? complianceLevelId;
  final String complianceLevelName;

  PatientMedicalHistoryRow copyWith({bool? isOnMedication}) {
    return PatientMedicalHistoryRow(
      id: id,
      patientId: patientId,
      conditionId: conditionId,
      conditionName: conditionName,
      durationInMonths: durationInMonths,
      isOnMedication: isOnMedication ?? this.isOnMedication,
      complianceLevelId: complianceLevelId,
      complianceLevelName: complianceLevelName,
    );
  }

  static PatientMedicalHistoryRow? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = _readInt(m, 'id', 'Id');
    if (id == null) return null;
    return PatientMedicalHistoryRow(
      id: id,
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      conditionId: _readInt(m, 'conditionId', 'ConditionId') ?? 0,
      conditionName: _readString(m, 'conditionName', 'ConditionName') ?? '',
      durationInMonths: _readInt(m, 'durationInMonths', 'DurationInMonths'),
      isOnMedication: _readBool(m, 'isOnMedication', 'IsOnMedication') ?? false,
      complianceLevelId:
          _readInt(m, 'complianceLevelId', 'ComplianceLevelId'),
      complianceLevelName:
          _readString(m, 'complianceLevelName', 'ComplianceLevelName') ?? '',
    );
  }
}

class PatientSurgicalHistoryRow {
  const PatientSurgicalHistoryRow({
    required this.id,
    required this.patientId,
    required this.procedureId,
    required this.procedureName,
    this.approxMonth,
    this.approxYear,
    required this.notes,
  });

  final int id;
  final String patientId;
  final int procedureId;
  final String procedureName;
  final int? approxMonth;
  final int? approxYear;
  final String notes;

  static PatientSurgicalHistoryRow? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = _readInt(m, 'id', 'Id');
    if (id == null) return null;
    return PatientSurgicalHistoryRow(
      id: id,
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      procedureId: _readInt(m, 'procedureId', 'ProcedureId') ?? 0,
      procedureName: _readString(m, 'procedureName', 'ProcedureName') ?? '',
      approxMonth: _readInt(m, 'approxMonth', 'ApproxMonth'),
      approxYear: _readInt(m, 'approxYear', 'ApproxYear'),
      notes: _readString(m, 'notes', 'Notes') ?? '',
    );
  }
}

class PatientDrugHistoryRow {
  const PatientDrugHistoryRow({
    required this.id,
    required this.patientId,
    required this.medicineCategoryId,
    required this.categoryName,
    this.adherenceLevelId,
    required this.adherenceLevelName,
    required this.sideEffects,
  });

  final int id;
  final String patientId;
  final int medicineCategoryId;
  final String categoryName;
  final int? adherenceLevelId;
  final String adherenceLevelName;
  final String sideEffects;

  static PatientDrugHistoryRow? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = _readInt(m, 'id', 'Id');
    if (id == null) return null;
    return PatientDrugHistoryRow(
      id: id,
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      medicineCategoryId:
          _readInt(m, 'medicineCategoryId', 'MedicineCategoryId') ?? 0,
      categoryName: _readString(m, 'categoryName', 'CategoryName') ?? '',
      adherenceLevelId:
          _readInt(m, 'adherenceLevelId', 'AdherenceLevelId'),
      adherenceLevelName:
          _readString(m, 'adherenceLevelName', 'AdherenceLevelName') ?? '',
      sideEffects: _readString(m, 'sideEffects', 'SideEffects') ?? '',
    );
  }
}

class PatientBaselineLifestyle {
  const PatientBaselineLifestyle({
    required this.patientId,
    required this.familyHistoryOfHtnOrStroke,
    required this.tobaccoUse,
  });

  final String patientId;
  final bool familyHistoryOfHtnOrStroke;
  final bool tobaccoUse;

  static PatientBaselineLifestyle? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    return PatientBaselineLifestyle(
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      familyHistoryOfHtnOrStroke:
          _readBool(m, 'familyHistoryOfHTNOrStroke', 'FamilyHistoryOfHTNOrStroke') ??
              _readBool(m, 'familyHistoryOfHtnOrStroke', 'FamilyHistoryOfHtnOrStroke') ??
              false,
      tobaccoUse: _readBool(m, 'tobaccoUse', 'TobaccoUse') ?? false,
    );
  }
}

class PatientVisitRow {
  const PatientVisitRow({
    required this.visitId,
    required this.patientId,
    required this.visitDate,
    required this.visitTypeName,
    required this.isFollowUpVisit,
    required this.reasonForVisit,
    this.avgSystolicBp,
    this.avgDiastolicBp,
    this.pulse,
    required this.visitStatusName,
    required this.visitActionName,
    this.medicalAdherenceNote,
    this.nextVisitDate,
  });

  final String visitId;
  final String patientId;
  final DateTime visitDate;
  final String visitTypeName;
  final bool isFollowUpVisit;
  final String reasonForVisit;
  final int? avgSystolicBp;
  final int? avgDiastolicBp;
  final int? pulse;
  final String visitStatusName;
  final String visitActionName;
  final String? medicalAdherenceNote;
  final DateTime? nextVisitDate;

  static PatientVisitRow? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final vd = _readDateTime(m, 'visitDate', 'VisitDate');
    if (vd == null) return null;
    return PatientVisitRow(
      visitId: _readString(m, 'visitId', 'VisitId') ?? '',
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      visitDate: vd,
      visitTypeName: _readString(m, 'visitTypeName', 'VisitTypeName') ?? '',
      isFollowUpVisit:
          _readBool(m, 'isFollowUpVisit', 'IsFollowUpVisit') ?? false,
      reasonForVisit:
          _readString(m, 'reasonForVisit', 'ReasonForVisit') ?? '',
      avgSystolicBp: _readInt(m, 'avgSystolicBP', 'AvgSystolicBP') ??
          _readInt(m, 'avgSystolicBp', 'AvgSystolicBp'),
      avgDiastolicBp: _readInt(m, 'avgDiastolicBP', 'AvgDiastolicBP') ??
          _readInt(m, 'avgDiastolicBp', 'AvgDiastolicBp'),
      pulse: _readInt(m, 'pulse', 'Pulse'),
      visitStatusName:
          _readString(m, 'visitStatusName', 'VisitStatusName') ?? '',
      visitActionName:
          _readString(m, 'visitActionName', 'VisitActionName') ?? '',
      medicalAdherenceNote:
          _readString(m, 'medicalAdherenceNote', 'MedicalAdherenceNote'),
      nextVisitDate: _readDateTime(m, 'nextVisitDate', 'NextVisitDate'),
    );
  }
}

Map<String, dynamic>? _unwrapDataMap(dynamic root) {
  if (root is Map) {
    final m = Map<String, dynamic>.from(root);
    final inner = m['data'] ?? m['Data'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return m;
  }
  return null;
}

String? _readString(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _readInt(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

bool? _readBool(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return null;
}

DateTime? _readDateTime(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v.trim());
  return null;
}
