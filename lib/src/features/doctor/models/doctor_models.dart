/// Doctor profile fields returned with login / session.
class DoctorProfileFields {
  const DoctorProfileFields({
    required this.doctorSpeciality,
    required this.pmdcNumber,
    required this.hospitalName,
    this.doctorId,
  });

  final String doctorSpeciality;
  final String pmdcNumber;
  final String hospitalName;
  final String? doctorId;

  static DoctorProfileFields? tryFromJson(
    dynamic json, {
    String? fallbackUserId,
  }) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final hospital = _readString(m, 'hospitalName', 'HospitalName');
    final specialty = _readString(m, 'doctorSpeciality', 'DoctorSpeciality') ??
        _readString(m, 'specialtyName', 'SpecialtyName') ??
        '';
    final pmdc = _readString(m, 'pmdcNumber', 'PMDCNumber') ?? '';
    final doctorId = _readString(m, 'doctorId', 'DoctorId') ??
        _readString(m, 'id', 'Id') ??
        _readString(m, 'professionId', 'ProfessionId') ??
        fallbackUserId;

    if ((hospital == null || hospital.trim().isEmpty) &&
        specialty.trim().isEmpty &&
        pmdc.trim().isEmpty &&
        (doctorId == null || doctorId.trim().isEmpty)) {
      return null;
    }

    return DoctorProfileFields(
      doctorSpeciality: specialty.trim(),
      pmdcNumber: pmdc.trim(),
      hospitalName: (hospital ?? '').trim(),
      doctorId: doctorId?.trim(),
    );
  }
}

class DoctorDashboardStats {
  const DoctorDashboardStats({
    required this.emergencyQueueCount,
    required this.patientsSeenToday,
    required this.earningsToday,
    required this.prescriptionsWrittenToday,
  });

  final int emergencyQueueCount;
  final int patientsSeenToday;
  final double earningsToday;
  final int prescriptionsWrittenToday;

  static DoctorDashboardStats? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final inner = m['data'] ?? m['Data'];
    final map = inner is Map ? Map<String, dynamic>.from(inner) : m;
    return DoctorDashboardStats(
      emergencyQueueCount:
          _readInt(map, 'emergencyQueueCount', 'EmergencyQueueCount') ?? 0,
      patientsSeenToday:
          _readInt(map, 'patientsSeenToday', 'PatientsSeenToday') ?? 0,
      earningsToday:
          _readDouble(map, 'earningsToday', 'EarningsToday') ?? 0,
      prescriptionsWrittenToday: _readInt(
            map,
            'prescriptionsWrittenToday',
            'PrescriptionsWrittenToday',
          ) ??
          0,
    );
  }
}

class DoctorQueuePatient {
  const DoctorQueuePatient({
    required this.patientId,
    required this.visitId,
    required this.patientNumber,
    required this.firstName,
    required this.lastName,
    required this.visitActionId,
  });

  final String patientId;
  final String visitId;
  final int patientNumber;
  final String firstName;
  final String lastName;
  final int visitActionId;

  String get fullName {
    final n = '$firstName $lastName'.trim();
    return n.isEmpty ? 'Patient' : n;
  }

  bool get isEmergency => visitActionId == 4;
  bool get isNormal => visitActionId == 3;

  static DoctorQueuePatient? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final patientId = _readString(m, 'patientId', 'PatientId') ??
        _readString(m, 'id', 'Id');
    if (patientId == null || patientId.isEmpty) return null;
    return DoctorQueuePatient(
      patientId: patientId,
      visitId: _readString(m, 'visitId', 'VisitId') ??
          _readString(m, 'visitID', 'VisitID') ??
          '',
      patientNumber: _readInt(m, 'patientNumber', 'PatientNumber') ?? 0,
      firstName: _readString(m, 'firstName', 'FirstName') ??
          _readString(m, 'patientFirstName', 'PatientFirstName') ??
          '',
      lastName: _readString(m, 'lastName', 'LastName') ??
          _readString(m, 'patientLastName', 'PatientLastName') ??
          '',
      visitActionId: _readInt(m, 'visitActionId', 'VisitActionId') ?? 0,
    );
  }
}

class PrescriptionMedicineInput {
  const PrescriptionMedicineInput({
    this.medicineId = 0,
    required this.customMedicineName,
    required this.dosageAmount,
    required this.frequency,
    required this.durationInDays,
  });

  final int medicineId;
  final String customMedicineName;
  final String dosageAmount;
  final String frequency;
  final int durationInDays;

  Map<String, dynamic> toJson() => {
        if (medicineId > 0) 'medicineId': medicineId,
        'customMedicineName': customMedicineName,
        'dosageAmount': dosageAmount,
        'frequency': frequency,
        'durationInDays': durationInDays,
      };
}

String? _prescriptionDateToJson(DateTime? value) {
  if (value == null) return null;
  final local = value.toLocal();
  // Match visit API: anchor at local noon so the calendar day does not shift.
  return DateTime(local.year, local.month, local.day, 12).toIso8601String();
}

class PrescriptionSubmitRequest {
  const PrescriptionSubmitRequest({
    required this.visitId,
    required this.patientId,
    required this.doctorId,
    required this.tenureInDays,
    required this.doctorNotes,
    this.continuedFromPrescriptionId,
    this.nextVisitDate,
    required this.medicines,
  });

  final String visitId;
  final String patientId;
  final String doctorId;
  final int tenureInDays;
  final String doctorNotes;
  final String? continuedFromPrescriptionId;
  final DateTime? nextVisitDate;
  final List<PrescriptionMedicineInput> medicines;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'visitId': visitId,
      'patientId': patientId,
      'doctorId': doctorId,
      'tenureInDays': tenureInDays,
      'doctorNotes': doctorNotes,
      'medicines': medicines.map((m) => m.toJson()).toList(),
    };
    final continued = continuedFromPrescriptionId?.trim();
    if (continued != null && continued.isNotEmpty) {
      map['continuedFromPrescriptionId'] = continued;
    }
    if (nextVisitDate != null) {
      final encoded = _prescriptionDateToJson(nextVisitDate);
      if (encoded != null) {
        map['nextVisitDate'] = encoded;
      }
    }
    return map;
  }
}

/// `PUT /api/Doctor/prescription` — PrescriptionEditModel.
class PrescriptionEditRequest {
  const PrescriptionEditRequest({
    required this.prescriptionId,
    required this.doctorId,
    required this.tenureInDays,
    required this.doctorNotes,
    this.continuedFromPrescriptionId,
    required this.medicines,
  });

  final String prescriptionId;
  final String doctorId;
  final int tenureInDays;
  final String doctorNotes;
  final String? continuedFromPrescriptionId;
  final List<PrescriptionMedicineInput> medicines;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'prescriptionId': prescriptionId,
      'doctorId': doctorId,
      'tenureInDays': tenureInDays,
      'doctorNotes': doctorNotes,
      'medicines': medicines.map((m) => m.toJson()).toList(),
    };
    final continued = continuedFromPrescriptionId?.trim();
    if (continued != null && continued.isNotEmpty) {
      map['continuedFromPrescriptionId'] = continued;
    }
    return map;
  }
}

class DoctorPrescriptionSummary {
  const DoctorPrescriptionSummary({
    required this.prescriptionId,
    required this.prescriptionDate,
    required this.patientName,
    required this.patientNumber,
    required this.patientGender,
    required this.visitId,
    required this.reasonForVisit,
    required this.prescribedMedicinesString,
    required this.doctorNotes,
  });

  final String prescriptionId;
  final DateTime? prescriptionDate;
  final String patientName;
  final int patientNumber;
  final String patientGender;
  final String visitId;
  final String reasonForVisit;
  final String prescribedMedicinesString;
  final String doctorNotes;

  static DoctorPrescriptionSummary? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = _readString(m, 'prescriptionId', 'PrescriptionId');
    if (id == null || id.isEmpty) return null;
    return DoctorPrescriptionSummary(
      prescriptionId: id,
      prescriptionDate: _readDateTime(
        m,
        'prescriptionDate',
        'PrescriptionDate',
      ),
      patientName: _readString(m, 'patientName', 'PatientName') ?? '',
      patientNumber: _readInt(m, 'patientNumber', 'PatientNumber') ?? 0,
      patientGender: _readString(m, 'patientGender', 'PatientGender') ?? '',
      visitId: _readString(m, 'visitId', 'VisitId') ?? '',
      reasonForVisit: _readString(m, 'reasonForVisit', 'ReasonForVisit') ?? '',
      prescribedMedicinesString: _readString(
            m,
            'prescribedMedicinesString',
            'PrescribedMedicinesString',
          ) ??
          '',
      doctorNotes: _readString(m, 'doctorNotes', 'DoctorNotes') ?? '',
    );
  }
}

class PatientPrescriptionHistoryItem {
  const PatientPrescriptionHistoryItem({
    required this.prescriptionId,
    required this.prescriptionDate,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.visitId,
    required this.reasonForVisit,
    required this.medicinesDetailString,
    required this.doctorNotes,
  });

  final String prescriptionId;
  final DateTime? prescriptionDate;
  final String doctorName;
  final String doctorSpecialty;
  final String visitId;
  final String reasonForVisit;
  final String medicinesDetailString;
  final String doctorNotes;

  static PatientPrescriptionHistoryItem? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = _readString(m, 'prescriptionId', 'PrescriptionId');
    if (id == null || id.isEmpty) return null;
    final specialtyRaw = m['doctorSpecialty'] ??
        m['DoctorSpecialty'] ??
        m['doctorSpeciality'] ??
        m['DoctorSpeciality'];
    return PatientPrescriptionHistoryItem(
      prescriptionId: id,
      prescriptionDate: _readDateTime(
        m,
        'prescriptionDate',
        'PrescriptionDate',
      ),
      doctorName: _readString(m, 'doctorName', 'DoctorName') ?? '',
      doctorSpecialty: specialtyRaw?.toString() ?? '',
      visitId: _readString(m, 'visitId', 'VisitId') ?? '',
      reasonForVisit: _readString(m, 'reasonForVisit', 'ReasonForVisit') ?? '',
      medicinesDetailString: _readString(
            m,
            'medicinesDetailString',
            'MedicinesDetailString',
          ) ??
          '',
      doctorNotes: _readString(m, 'doctorNotes', 'DoctorNotes') ?? '',
    );
  }
}

int? _readInt(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

double? _readDouble(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
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

dynamic unwrapListPayload(dynamic root) {
  if (root is List) return root;
  if (root is Map) {
    final m = Map<String, dynamic>.from(root);
    for (final key in [
      'data',
      'Data',
      'result',
      'Result',
      'patients',
      'Patients',
      'items',
      'Items',
      'queue',
      'Queue',
    ]) {
      final inner = m[key];
      if (inner is List) return inner;
    }
  }
  return root;
}
