import 'dart:convert';

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

/// `GET /api/Patient/complete-history/{patientId}` — matches
/// `PatientCompleteHistoryResponseModel` (JSON: `baselineLifestyle`, `medicalHistory`,
/// `surgicalHistory`, `drugHistory`, `patientLifeStyle`; PascalCase aliases supported).
class PatientCompleteHistoryData {
  const PatientCompleteHistoryData({
    this.baseline,
    this.patientLifeStyle,
    required this.medical,
    required this.surgical,
    required this.drugs,
  });

  final PatientBaselineLifestyle? baseline;
  final PatientLifeStyle? patientLifeStyle;
  final List<PatientMedicalHistoryRow> medical;
  final List<PatientSurgicalHistoryRow> surgical;
  final List<PatientDrugHistoryRow> drugs;

  static PatientCompleteHistoryData? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    var m = Map<String, dynamic>.from(json);
    final envelope = m['data'] ?? m['Data'];
    if (envelope is Map) {
      m = Map<String, dynamic>.from(envelope);
    }

    PatientBaselineLifestyle? baseline;
    final blRaw = m['baselineLifestyle'] ?? m['BaselineLifestyle'];
    if (blRaw is Map) {
      baseline = PatientBaselineLifestyle.tryFromJson(blRaw);
    }

    PatientLifeStyle? patientLifeStyle;
    final plsRaw = m['patientLifeStyle'] ?? m['PatientLifeStyle'];
    if (plsRaw is Map) {
      patientLifeStyle = PatientLifeStyle.tryFromJson(plsRaw);
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
      patientLifeStyle: patientLifeStyle,
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
    this.customConditionName = '',
    this.durationInMonths,
    required this.isOnMedication,
    this.complianceLevelId,
    required this.complianceLevelName,
  });

  final int id;
  final String patientId;
  final int conditionId;
  final String conditionName;
  final String customConditionName;
  final int? durationInMonths;
  final bool isOnMedication;
  final int? complianceLevelId;
  final String complianceLevelName;

  bool get isCustomCondition => customConditionName.trim().isNotEmpty;

  String get displayConditionName {
    final custom = customConditionName.trim();
    if (custom.isNotEmpty) return custom;
    return conditionName;
  }

  PatientMedicalHistoryRow copyWith({
    int? id,
    int? conditionId,
    String? conditionName,
    String? customConditionName,
    bool clearCustomCondition = false,
    bool? isOnMedication,
    int? durationInMonths,
    int? complianceLevelId,
    String? complianceLevelName,
    bool clearComplianceLevel = false,
  }) {
    return PatientMedicalHistoryRow(
      id: id ?? this.id,
      patientId: patientId,
      conditionId: conditionId ?? this.conditionId,
      conditionName: conditionName ?? this.conditionName,
      customConditionName: clearCustomCondition
          ? ''
          : (customConditionName ?? this.customConditionName),
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
      customConditionName:
          _readString(m, 'customConditionName', 'CustomConditionName') ?? '',
      durationInMonths: _readInt(m, 'durationInMonths', 'DurationInMonths'),
      isOnMedication: _readBool(m, 'isOnMedication', 'IsOnMedication') ?? false,
      complianceLevelId: _readInt(m, 'complianceLevelId', 'ComplianceLevelId'),
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
    this.customProcedureName = '',
    this.approxMonth,
    this.approxYear,
    required this.notes,
  });

  final int id;
  final String patientId;
  final int procedureId;
  final String procedureName;
  final String customProcedureName;
  final int? approxMonth;
  final int? approxYear;
  final String notes;

  bool get isCustomProcedure => customProcedureName.trim().isNotEmpty;

  String get displayProcedureName {
    final custom = customProcedureName.trim();
    if (custom.isNotEmpty) return custom;
    return procedureName;
  }

  PatientSurgicalHistoryRow copyWith({
    int? id,
    int? procedureId,
    String? procedureName,
    String? customProcedureName,
    bool clearCustomProcedure = false,
    int? approxMonth,
    int? approxYear,
    String? notes,
  }) {
    return PatientSurgicalHistoryRow(
      id: id ?? this.id,
      patientId: patientId,
      procedureId: procedureId ?? this.procedureId,
      procedureName: procedureName ?? this.procedureName,
      customProcedureName: clearCustomProcedure
          ? ''
          : (customProcedureName ?? this.customProcedureName),
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
      customProcedureName:
          _readString(m, 'customProcedureName', 'CustomProcedureName') ?? '',
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
    this.customMedicineCategoryName = '',
    this.adherenceLevelId,
    required this.adherenceLevelName,
    required this.sideEffects,
  });

  final int id;
  final String patientId;
  final int medicineCategoryId;
  final String categoryName;
  final String customMedicineCategoryName;
  final int? adherenceLevelId;
  final String adherenceLevelName;
  final String sideEffects;

  bool get isCustomCategory => customMedicineCategoryName.trim().isNotEmpty;

  String get displayCategoryName {
    final custom = customMedicineCategoryName.trim();
    if (custom.isNotEmpty) return custom;
    return categoryName;
  }

  PatientDrugHistoryRow copyWith({
    int? id,
    int? medicineCategoryId,
    String? categoryName,
    String? customMedicineCategoryName,
    bool clearCustomCategory = false,
    int? adherenceLevelId,
    String? adherenceLevelName,
    String? sideEffects,
    bool clearAdherenceLevel = false,
  }) {
    return PatientDrugHistoryRow(
      id: id ?? this.id,
      patientId: patientId,
      medicineCategoryId: medicineCategoryId ?? this.medicineCategoryId,
      categoryName: categoryName ?? this.categoryName,
      customMedicineCategoryName: clearCustomCategory
          ? ''
          : (customMedicineCategoryName ?? this.customMedicineCategoryName),
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
      customMedicineCategoryName: _readString(
            m,
            'customMedicineCategoryName',
            'CustomMedicineCategoryName',
          ) ??
          '',
      adherenceLevelId: _readInt(m, 'adherenceLevelId', 'AdherenceLevelId'),
      adherenceLevelName:
          _readString(m, 'adherenceLevelName', 'AdherenceLevelName') ?? '',
      sideEffects: _readString(m, 'sideEffects', 'SideEffects') ?? '',
    );
  }
}

class PatientFamilyConditionRow {
  const PatientFamilyConditionRow({
    required this.relativeConditionId,
    required this.conditionId,
    required this.conditionName,
    this.customConditionName = '',
  });

  final String relativeConditionId;
  final int conditionId;
  final String conditionName;
  final String customConditionName;

  bool get isDraft =>
      relativeConditionId.trim().isEmpty ||
      relativeConditionId.startsWith('local-');

  bool get isCustomCondition => customConditionName.trim().isNotEmpty;

  String get displayConditionName {
    final custom = customConditionName.trim();
    if (custom.isNotEmpty) return custom;
    final name = conditionName.trim();
    if (name.isNotEmpty) return name;
    if (conditionId > 0) return 'Condition #$conditionId';
    return '';
  }

  PatientFamilyConditionRow copyWith({
    String? relativeConditionId,
    int? conditionId,
    String? conditionName,
    String? customConditionName,
    bool clearCustomCondition = false,
  }) {
    return PatientFamilyConditionRow(
      relativeConditionId: relativeConditionId ?? this.relativeConditionId,
      conditionId: conditionId ?? this.conditionId,
      conditionName: conditionName ?? this.conditionName,
      customConditionName: clearCustomCondition
          ? ''
          : (customConditionName ?? this.customConditionName),
    );
  }

  static PatientFamilyConditionRow? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    var rcId = _readString(
          m,
          'relativeConditionId',
          'RelativeConditionId',
        ) ??
        _readString(m, 'patientRelativeConditionId', 'PatientRelativeConditionId');
    if (rcId == null || rcId.isEmpty) {
      rcId = _readString(m, 'id', 'Id');
    }
    if (rcId == null || rcId.isEmpty) {
      final intId = _readInt(m, 'relativeConditionId', 'RelativeConditionId') ??
          _readInt(m, 'patientRelativeConditionId', 'PatientRelativeConditionId') ??
          _readInt(m, 'id', 'Id');
      if (intId != null && intId > 0) rcId = intId.toString();
    }

    final conditionId = _readFamilyConditionId(m);
    final conditionName = _readFamilyConditionName(m);
    final customConditionName = _readFamilyCustomConditionName(m);

    if (rcId == null || rcId.isEmpty) {
      if (conditionId <= 0 &&
          customConditionName.isEmpty &&
          conditionName.isEmpty) {
        return null;
      }
      return PatientFamilyConditionRow(
        relativeConditionId: '',
        conditionId: conditionId,
        conditionName: conditionName,
        customConditionName: customConditionName,
      );
    }

    return PatientFamilyConditionRow(
      relativeConditionId: rcId,
      conditionId: conditionId,
      conditionName: conditionName,
      customConditionName: customConditionName,
    );
  }
}

class PatientFamilyRelativeRow {
  const PatientFamilyRelativeRow({
    required this.relativeId,
    required this.patientId,
    required this.relationDegreeId,
    required this.relationDegreeName,
    required this.specificRelation,
    required this.conditions,
  });

  final int relativeId;
  final String patientId;
  final int relationDegreeId;
  final String relationDegreeName;
  final String specificRelation;
  final List<PatientFamilyConditionRow> conditions;

  bool get isDraft => relativeId <= 0;

  String get displayTitle {
    final spec = specificRelation.trim();
    if (spec.isNotEmpty) return spec;
    final degree = relationDegreeName.trim();
    if (degree.isNotEmpty) return degree;
    return 'Relative';
  }

  PatientFamilyRelativeRow copyWith({
    int? relativeId,
    int? relationDegreeId,
    String? relationDegreeName,
    String? specificRelation,
    List<PatientFamilyConditionRow>? conditions,
  }) {
    return PatientFamilyRelativeRow(
      relativeId: relativeId ?? this.relativeId,
      patientId: patientId,
      relationDegreeId: relationDegreeId ?? this.relationDegreeId,
      relationDegreeName: relationDegreeName ?? this.relationDegreeName,
      specificRelation: specificRelation ?? this.specificRelation,
      conditions: conditions ?? this.conditions,
    );
  }

  static PatientFamilyRelativeRow? tryFromJson(
    dynamic json, {
    int? fallbackDegreeId,
    String fallbackDegreeName = '',
  }) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final relativeId = _readInt(m, 'relativeId', 'RelativeId') ??
        _readInt(m, 'patientRelativeId', 'PatientRelativeId') ??
        _readInt(m, 'id', 'Id');
    if (relativeId == null || relativeId <= 0) return null;

    final conditions = <PatientFamilyConditionRow>[];
    final condRaw = m['conditions'] ??
        m['Conditions'] ??
        m['relativeConditions'] ??
        m['RelativeConditions'] ??
        m['patientRelativeConditions'] ??
        m['PatientRelativeConditions'] ??
        m['illnesses'] ??
        m['Illnesses'];
    if (condRaw is List) {
      for (final item in condRaw) {
        final row = PatientFamilyConditionRow.tryFromJson(item);
        if (row != null) conditions.add(row);
      }
    }

    var relationDegreeId =
        _readInt(m, 'relationDegreeId', 'RelationDegreeId') ??
        _readInt(m, 'patientRelationDegreeId', 'PatientRelationDegreeId') ??
        _readInt(m, 'degreeId', 'DegreeId') ??
        0;
    var relationDegreeName =
        _readString(m, 'relationDegreeName', 'RelationDegreeName') ??
        _readString(m, 'degreeName', 'DegreeName') ??
        _readString(m, 'relationDegree', 'RelationDegree') ??
        '';
    if (relationDegreeId <= 0) {
      final nested = m['relationDegree'] ?? m['RelationDegree'];
      if (nested is Map) {
        final nm = Map<String, dynamic>.from(nested);
        relationDegreeId = _readInt(nm, 'relationDegreeId', 'RelationDegreeId') ??
            _readInt(nm, 'id', 'Id') ??
            relationDegreeId;
        relationDegreeName = _readString(nm, 'name', 'Name') ??
            _readString(nm, 'relationDegreeName', 'RelationDegreeName') ??
            relationDegreeName;
      }
    }
    if (relationDegreeId <= 0 &&
        fallbackDegreeId != null &&
        fallbackDegreeId > 0) {
      relationDegreeId = fallbackDegreeId;
    }
    if (relationDegreeName.isEmpty && fallbackDegreeName.isNotEmpty) {
      relationDegreeName = fallbackDegreeName;
    }

    return PatientFamilyRelativeRow(
      relativeId: relativeId,
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      relationDegreeId: relationDegreeId,
      relationDegreeName: relationDegreeName,
      specificRelation:
          _readString(m, 'specificRelation', 'SpecificRelation') ?? '',
      conditions: conditions,
    );
  }
}

class PatientFamilyHistoryData {
  const PatientFamilyHistoryData({required this.relatives});

  final List<PatientFamilyRelativeRow> relatives;

  static PatientFamilyHistoryData? tryFromJson(dynamic json) {
    final raw = _extractFamilyHistoryRawList(json);
    if (raw != null) {
      return PatientFamilyHistoryData(relatives: _parseRelativesFromRaw(raw));
    }

    if (json is Map) {
      var m = Map<String, dynamic>.from(json);
      final envelope = m['data'] ?? m['Data'] ?? m['result'] ?? m['Result'];
      if (envelope is Map) {
        m = Map<String, dynamic>.from(envelope);
      }
      final fromMap = _parseRelativesFromDegreeMap(m);
      if (fromMap.isNotEmpty) {
        return PatientFamilyHistoryData(relatives: fromMap);
      }
    }

    return const PatientFamilyHistoryData(relatives: []);
  }

  static List<dynamic>? _extractFamilyHistoryRawList(dynamic json) {
    if (json is List) return json;
    if (json is! Map) return null;

    var m = Map<String, dynamic>.from(json);
    final envelope = m['data'] ?? m['Data'] ?? m['result'] ?? m['Result'];
    if (envelope is List) return envelope;
    if (envelope is Map) {
      m = Map<String, dynamic>.from(envelope);
    }

    for (final key in const [
      'relatives',
      'Relatives',
      'familyHistory',
      'FamilyHistory',
      'patientFamilyHistory',
      'PatientFamilyHistory',
      'familyHistoryByDegree',
      'FamilyHistoryByDegree',
    ]) {
      final value = m[key];
      if (value is List) return value;
    }

    final flattened = <dynamic>[];
    for (final value in m.values) {
      if (value is! List || value.isEmpty) continue;
      if (value.first is Map) flattened.addAll(value);
    }
    if (flattened.isNotEmpty) return flattened;

    return null;
  }

  static List<PatientFamilyRelativeRow> _parseRelativesFromRaw(
    List<dynamic> raw,
  ) {
    final relatives = <PatientFamilyRelativeRow>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);

      final nested = m['relatives'] ??
          m['Relatives'] ??
          m['patientRelatives'] ??
          m['PatientRelatives'] ??
          m['familyRelatives'] ??
          m['FamilyRelatives'] ??
          m['items'] ??
          m['Items'] ??
          m['members'] ??
          m['Members'];
      if (nested is List) {
        final groupDegreeId = _readInt(m, 'relationDegreeId', 'RelationDegreeId') ??
            _readInt(m, 'patientRelationDegreeId', 'PatientRelationDegreeId') ??
            _readInt(m, 'degreeId', 'DegreeId');
        final groupDegreeName =
            _readString(m, 'relationDegreeName', 'RelationDegreeName') ??
            _readString(m, 'degreeName', 'DegreeName') ??
            _readString(m, 'name', 'Name') ??
            '';
        for (final relItem in nested) {
          final row = PatientFamilyRelativeRow.tryFromJson(
            relItem,
            fallbackDegreeId: groupDegreeId,
            fallbackDegreeName: groupDegreeName,
          );
          if (row != null) relatives.add(row);
        }
        continue;
      }

      final row = PatientFamilyRelativeRow.tryFromJson(item);
      if (row != null) relatives.add(row);
    }
    return relatives;
  }

  static List<PatientFamilyRelativeRow> _parseRelativesFromDegreeMap(
    Map<String, dynamic> m,
  ) {
    final relatives = <PatientFamilyRelativeRow>[];
    for (final entry in m.entries) {
      final value = entry.value;
      if (value is! List || value.isEmpty) continue;

      final key = entry.key.trim();
      final keyDegreeId = int.tryParse(key);
      final fallbackName = keyDegreeId == null ? key : '';

      if (value.first is Map) {
        final first = Map<String, dynamic>.from(value.first as Map);
        final isDegreeGroup = first.containsKey('relatives') ||
            first.containsKey('Relatives') ||
            first.containsKey('patientRelatives') ||
            first.containsKey('PatientRelatives');
        if (isDegreeGroup) {
          relatives.addAll(_parseRelativesFromRaw(value));
          continue;
        }
      }

      for (final relItem in value) {
        final row = PatientFamilyRelativeRow.tryFromJson(
          relItem,
          fallbackDegreeId: keyDegreeId,
          fallbackDegreeName: fallbackName,
        );
        if (row != null) relatives.add(row);
      }
    }
    return relatives;
  }
}

class PatientBaselineLifestyle {
  const PatientBaselineLifestyle({
    required this.patientId,
    required this.familyHistoryOfHtnOrStroke,
    required this.tobaccoUse,
    this.tobaccoType,
    this.tobaccoQuantityPerDay,
    this.tobaccoDurationStart,
    this.tobaccoDurationEnd,
  });

  final String patientId;
  final bool familyHistoryOfHtnOrStroke;
  final bool tobaccoUse;
  final String? tobaccoType;
  final int? tobaccoQuantityPerDay;
  final DateTime? tobaccoDurationStart;
  final DateTime? tobaccoDurationEnd;

  static PatientBaselineLifestyle? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    return PatientBaselineLifestyle(
      patientId: _readString(m, 'patientId', 'PatientId') ?? '',
      familyHistoryOfHtnOrStroke: _readBool(
              m, 'familyHistoryOfHTNOrStroke', 'FamilyHistoryOfHTNOrStroke') ??
          _readBool(
              m, 'familyHistoryOfHtnOrStroke', 'FamilyHistoryOfHtnOrStroke') ??
          false,
      tobaccoUse: _readBool(m, 'tobaccoUse', 'TobaccoUse') ?? false,
      tobaccoType: _readString(m, 'tobaccoType', 'TobaccoType'),
      tobaccoQuantityPerDay:
          _readInt(m, 'tobaccoQuantityPerDay', 'TobaccoQuantityPerDay'),
      tobaccoDurationStart:
          _readDateTime(m, 'tobaccoDurationStart', 'TobaccoDurationStart'),
      tobaccoDurationEnd:
          _readDateTime(m, 'tobaccoDurationEnd', 'TobaccoDurationEnd'),
    );
  }
}

/// `GET|PUT /api/Patient/lifestyle` — meals, sleep, exercise, salt, alcohol.
class PatientLifeStyle {
  const PatientLifeStyle({
    required this.patientId,
    this.breakfast = '',
    this.lunch = '',
    this.snacks = '',
    this.dinner = '',
    this.nightSleepHours,
    this.daySleepHours,
    this.exerciseLevelId,
    this.exerciseLevelName = '',
    required this.alcoholUse,
    required this.highSaltDiet,
  });

  final String patientId;
  final String breakfast;
  final String lunch;
  final String snacks;
  final String dinner;
  final double? nightSleepHours;
  final double? daySleepHours;
  final int? exerciseLevelId;
  final String exerciseLevelName;
  final bool alcoholUse;
  final bool highSaltDiet;

  static PatientLifeStyle? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final patientId = _readString(m, 'patientId', 'PatientId') ?? '';
    return PatientLifeStyle(
      patientId: patientId,
      breakfast: _readString(m, 'breakfast', 'Breakfast') ?? '',
      lunch: _readString(m, 'lunch', 'Lunch') ?? '',
      snacks: _readString(m, 'snacks', 'Snacks') ?? '',
      dinner: _readString(m, 'dinner', 'Dinner') ?? '',
      nightSleepHours:
          _readDouble(m, 'nightSleepHours', 'NightSleepHours'),
      daySleepHours: _readDouble(m, 'daySleepHours', 'DaySleepHours'),
      exerciseLevelId: _readInt(m, 'exerciseLevelId', 'ExerciseLevelId'),
      exerciseLevelName:
          _readString(m, 'exerciseLevelName', 'ExerciseLevelName') ?? '',
      alcoholUse: _readBool(m, 'alcoholUse', 'AlcoholUse') ?? false,
      highSaltDiet: _readBool(m, 'highSaltDiet', 'HighSaltDiet') ?? false,
    );
  }
}

/// `GET /api/Patient/counselling-instructison` — text-only counselling list.
class CounsellingInstruction {
  const CounsellingInstruction({
    required this.id,
    required this.instructionName,
  });

  final int id;
  final String instructionName;

  static CounsellingInstruction? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final instructionName = _readString(m, 'instructionName', 'InstructionName') ??
        _readString(m, 'instruction', 'Instruction') ??
        _readString(m, 'name', 'Name') ??
        '';
    if (instructionName.isEmpty) return null;

    final id = _readInt(m, 'id', 'Id') ?? 0;
    return CounsellingInstruction(
      id: id,
      instructionName: instructionName,
    );
  }
}

List<CounsellingInstruction> parseCounsellingInstructionsList(dynamic root) {
  final raw = _unwrapEnvelopeList(root);
  final out = <CounsellingInstruction>[];
  for (var i = 0; i < raw.length; i++) {
    final row = CounsellingInstruction.tryFromJson(raw[i]);
    if (row != null) {
      out.add(row);
      continue;
    }
    final text = raw[i]?.toString().trim() ?? '';
    if (text.isNotEmpty) {
      out.add(CounsellingInstruction(id: i + 1, instructionName: text));
    }
  }
  out.sort((a, b) {
    if (a.id != 0 && b.id != 0) return a.id.compareTo(b.id);
    return a.instructionName.compareTo(b.instructionName);
  });
  return out;
}

List<dynamic> _unwrapEnvelopeList(dynamic root) {
  root = _normalizeJsonRoot(root);
  if (root is List) return root;
  if (root is Map) {
    final m = Map<String, dynamic>.from(root);
    final envelope = m['data'] ?? m['Data'] ?? m['result'] ?? m['Result'];
    if (envelope is List) return envelope;
    if (envelope is Map) {
      final nested = _listFromMap(Map<String, dynamic>.from(envelope));
      if (nested != null) return nested;
    }
    final direct = _listFromMap(m);
    if (direct != null) return direct;
  }
  return const [];
}

dynamic _normalizeJsonRoot(dynamic root) {
  if (root is String) {
    final trimmed = root.trim();
    if (trimmed.isEmpty) return root;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return root;
    }
  }
  return root;
}

List<dynamic>? _listFromMap(Map<String, dynamic> m) {
  for (final key in const [
    'counsellingInstructions',
    'CounsellingInstructions',
    'instructions',
    'Instructions',
    'items',
    'Items',
    'records',
    'Records',
    'results',
    'Results',
    r'$values',
  ]) {
    final value = m[key];
    if (value is List) return value;
  }
  return null;
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
      reasonForVisit: _readString(m, 'reasonForVisit', 'ReasonForVisit') ?? '',
      avgSystolicBp: _readInt(m, 'avgSystolicBP', 'AvgSystolicBP') ??
          _readInt(m, 'avgSystolicBp', 'AvgSystolicBp') ??
          _readInt(m, 'systolicBP1', 'SystolicBP1') ??
          _readInt(m, 'systolicBp1', 'SystolicBp1'),
      avgDiastolicBp: _readInt(m, 'avgDiastolicBP', 'AvgDiastolicBP') ??
          _readInt(m, 'avgDiastolicBp', 'AvgDiastolicBp') ??
          _readInt(m, 'diastolicBP1', 'DiastolicBP1') ??
          _readInt(m, 'diastolicBp1', 'DiastolicBp1'),
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

double? _readDouble(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
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

Map<String, dynamic>? _nestedFamilyMap(
  Map<String, dynamic> m,
  List<String> keys,
) {
  for (final key in keys) {
    final nested = m[key];
    if (nested is Map) return Map<String, dynamic>.from(nested);
  }
  return null;
}

int _readFamilyConditionId(Map<String, dynamic> m) {
  var id = _readInt(m, 'conditionId', 'ConditionId') ??
      _readInt(m, 'medicalConditionId', 'MedicalConditionId') ??
      0;
  if (id > 0) return id;

  final nested = _nestedFamilyMap(m, const [
    'condition',
    'Condition',
    'medicalCondition',
    'MedicalCondition',
  ]);
  if (nested == null) return 0;

  return _readInt(nested, 'conditionId', 'ConditionId') ??
      _readInt(nested, 'medicalConditionId', 'MedicalConditionId') ??
      _readInt(nested, 'id', 'Id') ??
      0;
}

String _readFamilyConditionName(Map<String, dynamic> m) {
  final direct = _readString(m, 'conditionName', 'ConditionName') ??
      _readString(m, 'medicalConditionName', 'MedicalConditionName') ??
      _readString(m, 'name', 'Name') ??
      '';
  if (direct.isNotEmpty) return direct;

  final nested = _nestedFamilyMap(m, const [
    'condition',
    'Condition',
    'medicalCondition',
    'MedicalCondition',
  ]);
  if (nested == null) return '';

  return _readString(nested, 'conditionName', 'ConditionName') ??
      _readString(nested, 'medicalConditionName', 'MedicalConditionName') ??
      _readString(nested, 'name', 'Name') ??
      '';
}

String _readFamilyCustomConditionName(Map<String, dynamic> m) {
  final direct =
      _readString(m, 'customConditionName', 'CustomConditionName') ?? '';
  if (direct.isNotEmpty) return direct;

  final nested = _nestedFamilyMap(m, const [
    'condition',
    'Condition',
    'medicalCondition',
    'MedicalCondition',
  ]);
  if (nested == null) return '';

  return _readString(nested, 'customConditionName', 'CustomConditionName') ?? '';
}
