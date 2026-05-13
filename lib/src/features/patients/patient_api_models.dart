/// `GET /api/Patient/{patientId}` — `PatientProfileResponseModel` (camelCase JSON).
class PatientProfileData {
  const PatientProfileData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.maritalStatusId,
    required this.cnic,
    required this.contactNumber,
    required this.address,
    required this.assignedHealthWorkerId,
    this.provinceId,
    this.districtId,
    this.tehsilId,
    required this.patientNumber,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final int? maritalStatusId;
  final String cnic;
  final String contactNumber;
  final String address;
  final String assignedHealthWorkerId;
  final int? provinceId;
  final int? districtId;
  final int? tehsilId;
  final int patientNumber;

  static PatientProfileData? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = _readString(m, 'id', 'Id');
    if (id == null || id.isEmpty) return null;
    final dobRaw = m['dateOfBirth'] ?? m['DateOfBirth'];
    DateTime? dob;
    if (dobRaw is String && dobRaw.trim().isNotEmpty) {
      dob = DateTime.tryParse(dobRaw.trim());
    }
    return PatientProfileData(
      id: id,
      firstName: _readString(m, 'firstName', 'FirstName') ?? '',
      lastName: _readString(m, 'lastName', 'LastName') ?? '',
      gender: _readString(m, 'gender', 'Gender') ?? '',
      dateOfBirth: dob,
      maritalStatusId: _readInt(m, 'maritalStatusId', 'MaritalStatusId'),
      cnic: _readString(m, 'cnic', 'CNIC') ?? '',
      contactNumber: _readString(m, 'contactNumber', 'ContactNumber') ?? '',
      address: _readString(m, 'address', 'Address') ?? '',
      assignedHealthWorkerId:
          _readString(m, 'assignedHealthWorkerId', 'AssignedHealthWorkerId') ??
              '',
      provinceId: _readInt(m, 'provinceId', 'ProvinceId'),
      districtId: _readInt(m, 'districtId', 'DistrictId'),
      tehsilId: _readInt(m, 'tehsilId', 'TehsilId'),
      patientNumber: _readInt(m, 'patientNumber', 'PatientNumber') ?? 0,
    );
  }
}

/// `GET /api/Patient/complete-history/{patientId}` aggregate (camelCase JSON).
class PatientCompleteHistoryData {
  const PatientCompleteHistoryData({
    this.baseline,
    required this.medical,
    required this.surgical,
    required this.drugs,
  });

  final PatientBaselineLifestyle? baseline;
  final List<PatientMedicalHistoryRow> medical;
  final List<PatientSurgicalHistoryRow> surgical;
  final List<PatientDrugHistoryRow> drugs;

  static PatientCompleteHistoryData? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);

    PatientBaselineLifestyle? baseline;
    final blRaw = m['baselineLifestyle'] ?? m['BaselineLifestyle'];
    if (blRaw is Map) {
      baseline = PatientBaselineLifestyle.tryFromJson(blRaw);
    }

    final medical = <PatientMedicalHistoryRow>[];
    final medRaw = m['medicalHistory'] ?? m['MedicalHistory'];
    if (medRaw is List) {
      for (final item in medRaw) {
        final row = PatientMedicalHistoryRow.tryFromJson(item);
        if (row != null) medical.add(row);
      }
    }

    final surgical = <PatientSurgicalHistoryRow>[];
    final surgRaw = m['surgicalHistory'] ?? m['SurgicalHistory'];
    if (surgRaw is List) {
      for (final item in surgRaw) {
        final row = PatientSurgicalHistoryRow.tryFromJson(item);
        if (row != null) surgical.add(row);
      }
    }

    final drugs = <PatientDrugHistoryRow>[];
    final drugRaw = m['drugHistory'] ?? m['DrugHistory'];
    if (drugRaw is List) {
      for (final item in drugRaw) {
        final row = PatientDrugHistoryRow.tryFromJson(item);
        if (row != null) drugs.add(row);
      }
    }

    return PatientCompleteHistoryData(
      baseline: baseline,
      medical: medical,
      surgical: surgical,
      drugs: drugs,
    );
  }
}

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

  PatientMedicalHistoryRow copyWith({
    bool? isOnMedication,
    int? durationInMonths,
    int? complianceLevelId,
    String? complianceLevelName,
    bool clearComplianceLevel = false,
  }) {
    return PatientMedicalHistoryRow(
      id: id,
      patientId: patientId,
      conditionId: conditionId,
      conditionName: conditionName,
      durationInMonths: durationInMonths ?? this.durationInMonths,
      isOnMedication: isOnMedication ?? this.isOnMedication,
      complianceLevelId: clearComplianceLevel
          ? null
          : (complianceLevelId ?? this.complianceLevelId),
      complianceLevelName: clearComplianceLevel
          ? ''
          : (complianceLevelName ?? this.complianceLevelName),
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

  PatientSurgicalHistoryRow copyWith({
    int? approxMonth,
    int? approxYear,
    String? notes,
  }) {
    return PatientSurgicalHistoryRow(
      id: id,
      patientId: patientId,
      procedureId: procedureId,
      procedureName: procedureName,
      approxMonth: approxMonth ?? this.approxMonth,
      approxYear: approxYear ?? this.approxYear,
      notes: notes ?? this.notes,
    );
  }

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

  PatientDrugHistoryRow copyWith({
    int? adherenceLevelId,
    String? adherenceLevelName,
    String? sideEffects,
    bool clearAdherenceLevel = false,
  }) {
    return PatientDrugHistoryRow(
      id: id,
      patientId: patientId,
      medicineCategoryId: medicineCategoryId,
      categoryName: categoryName,
      adherenceLevelId: clearAdherenceLevel
          ? null
          : (adherenceLevelId ?? this.adherenceLevelId),
      adherenceLevelName: clearAdherenceLevel
          ? ''
          : (adherenceLevelName ?? this.adherenceLevelName),
      sideEffects: sideEffects ?? this.sideEffects,
    );
  }

  static PatientDrugHistoryRow? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = _readInt(m, 'id', 'Id');
    if (id == null) return null;
    final catName = _readString(m, 'categoryName', 'CategoryName') ??
        _readString(m, 'medicineCategoryName', 'MedicineCategoryName');

    return PatientDrugHistoryRow(
      id: id,
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      medicineCategoryId:
          _readInt(m, 'medicineCategoryId', 'MedicineCategoryId') ?? 0,
      categoryName: catName ?? '',
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
