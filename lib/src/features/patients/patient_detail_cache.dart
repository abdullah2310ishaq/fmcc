import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';

typedef PatientLocationRef = ({int id, String name});

/// App-wide reference lists + per-patient detail bundle (in-memory).
class PatientDetailCache extends ChangeNotifier {
  PatientDetailReferences? _references;
  final Map<String, PatientDetailBundle> _patients = {};

  bool get hasReferences => _references != null;

  PatientDetailReferences? get references => _references;

  bool hasPatient(String patientId) => _patients.containsKey(patientId);

  PatientDetailBundle? bundleFor(String patientId) => _patients[patientId];

  void setReferences(PatientDetailReferences refs) {
    _references = refs;
    notifyListeners();
  }

  void setPatientBundle(String patientId, PatientDetailBundle bundle) {
    _patients[patientId] = bundle;
    notifyListeners();
  }

  void invalidatePatient(String patientId) {
    if (_patients.remove(patientId) != null) {
      notifyListeners();
    }
  }

  void clearAll() {
    _references = null;
    _patients.clear();
    notifyListeners();
  }
}

class PatientDetailReferences {
  const PatientDetailReferences({
    required this.provinces,
    required this.maritalStatuses,
    required this.complianceLevels,
    required this.adherenceLevels,
    required this.medicalConditions,
    required this.surgicalProcedures,
    required this.medicineCategories,
    required this.relationDegrees,
  });

  final List<PatientLocationRef> provinces;
  final List<PatientLocationRef> maritalStatuses;
  final List<NamedReferenceItem> complianceLevels;
  final List<NamedReferenceItem> adherenceLevels;
  final List<NamedReferenceItem> medicalConditions;
  final List<NamedReferenceItem> surgicalProcedures;
  final List<NamedReferenceItem> medicineCategories;
  final List<NamedReferenceItem> relationDegrees;
}

class PatientDetailBundle {
  const PatientDetailBundle({
    required this.profile,
    required this.districts,
    required this.tehsils,
    this.history,
    required this.visits,
    this.familyRelatives,
  });

  final PatientProfileData profile;
  final List<PatientLocationRef> districts;
  final List<PatientLocationRef> tehsils;
  final PatientCompleteHistoryData? history;
  final List<PatientVisitRow> visits;
  final List<PatientFamilyRelativeRow>? familyRelatives;

  PatientDetailBundle copyWith({
    PatientProfileData? profile,
    List<PatientLocationRef>? districts,
    List<PatientLocationRef>? tehsils,
    PatientCompleteHistoryData? history,
    List<PatientVisitRow>? visits,
    List<PatientFamilyRelativeRow>? familyRelatives,
  }) {
    return PatientDetailBundle(
      profile: profile ?? this.profile,
      districts: districts ?? this.districts,
      tehsils: tehsils ?? this.tehsils,
      history: history ?? this.history,
      visits: visits ?? this.visits,
      familyRelatives: familyRelatives ?? this.familyRelatives,
    );
  }
}
