import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:doctor_app/src/features/patients/patient_api_models.dart';

/// Persists per-patient clinical history on device so data survives app restarts
/// when `GET …/complete-history` returns 404 for partial records.
class PatientDetailDiskCache {
  PatientDetailDiskCache._();

  static const _prefix = 'patient.detail.history.';

  static Future<void> save(
    String patientId,
    PatientCompleteHistoryData? history,
  ) async {
    if (patientId.trim().isEmpty || history == null) return;
    final hasAny = history.medical.isNotEmpty ||
        history.surgical.isNotEmpty ||
        history.drugs.isNotEmpty ||
        history.baseline != null;
    if (!hasAny) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefix + patientId, jsonEncode(_toJson(history)));
  }

  static Future<PatientCompleteHistoryData?> load(String patientId) async {
    if (patientId.trim().isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefix + patientId);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return _fromJson(decoded);
    } on Object {
      return null;
    }
  }

  static Future<void> clearPatient(String patientId) async {
    if (patientId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefix + patientId);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList(growable: false);
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  static Map<String, dynamic> _toJson(PatientCompleteHistoryData history) {
    return {
      'medicalHistory': history.medical.map(_medicalToJson).toList(),
      'surgicalHistory': history.surgical.map(_surgicalToJson).toList(),
      'drugHistory': history.drugs.map(_drugToJson).toList(),
      if (history.baseline != null)
        'baselineLifestyle': _baselineToJson(history.baseline!),
    };
  }

  static PatientCompleteHistoryData? _fromJson(dynamic root) {
    return PatientCompleteHistoryData.tryFromJson(root);
  }

  static Map<String, dynamic> _medicalToJson(PatientMedicalHistoryRow r) => {
        'id': r.id,
        'patientId': r.patientId,
        'conditionId': r.conditionId,
        'conditionName': r.conditionName,
        'customConditionName': r.customConditionName,
        'durationInMonths': r.durationInMonths,
        'isOnMedication': r.isOnMedication,
        'complianceLevelId': r.complianceLevelId,
        'complianceLevelName': r.complianceLevelName,
      };

  static Map<String, dynamic> _surgicalToJson(PatientSurgicalHistoryRow r) => {
        'id': r.id,
        'patientId': r.patientId,
        'procedureId': r.procedureId,
        'procedureName': r.procedureName,
        'customProcedureName': r.customProcedureName,
        'approxMonth': r.approxMonth,
        'approxYear': r.approxYear,
        'notes': r.notes,
      };

  static Map<String, dynamic> _drugToJson(PatientDrugHistoryRow r) => {
        'id': r.id,
        'patientId': r.patientId,
        'medicineCategoryId': r.medicineCategoryId,
        'categoryName': r.categoryName,
        'customMedicineCategoryName': r.customMedicineCategoryName,
        'adherenceLevelId': r.adherenceLevelId,
        'adherenceLevelName': r.adherenceLevelName,
        'sideEffects': r.sideEffects,
      };

  static Map<String, dynamic> _baselineToJson(PatientBaselineLifestyle b) => {
        'patientId': b.patientId,
        'familyHistoryOfHTNOrStroke': b.familyHistoryOfHtnOrStroke,
        'tobaccoUse': b.tobaccoUse,
        'tobaccoType': b.tobaccoType,
        'tobaccoQuantityPerDay': b.tobaccoQuantityPerDay,
        'tobaccoDurationStart': b.tobaccoDurationStart?.toIso8601String(),
        'tobaccoDurationEnd': b.tobaccoDurationEnd?.toIso8601String(),
      };
}
