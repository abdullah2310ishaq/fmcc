import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

class MedicineFormRow {
  MedicineFormRow({
    this.medicineId = 0,
    this.customMedicineName = '',
    this.dosageAmount = '',
    this.frequency = '',
    this.durationInDays = '',
  });

  int medicineId;
  String customMedicineName;
  String dosageAmount;
  String frequency;
  String durationInDays;
}

class PrescriptionFormController extends ChangeNotifier {
  PrescriptionFormController({
    required DoctorApi api,
    required ApiClient apiClient,
  })  : _api = api,
        _apiClient = apiClient;

  final DoctorApi _api;
  final ApiClient _apiClient;

  final List<MedicineFormRow> medicines = [MedicineFormRow()];

  String tenureInDays = '';
  String doctorNotes = '';
  String continuedFromPrescriptionId = '';
  DateTime? nextVisitDate;

  bool submitting = false;
  String? formError;
  bool _dirty = false;

  bool get hasUnsavedChanges => _dirty;

  void markDirty() {
    if (_dirty) return;
    _dirty = true;
    notifyListeners();
  }

  void addMedicine() {
    medicines.add(MedicineFormRow());
    markDirty();
    notifyListeners();
  }

  void removeMedicine(int index) {
    if (medicines.length <= 1) return;
    medicines.removeAt(index);
    markDirty();
    notifyListeners();
  }

  void setNextVisitDate(DateTime? value) {
    nextVisitDate = value;
    markDirty();
    notifyListeners();
  }

  void loadForEdit({
    required int tenure,
    required String notes,
    String? continuedFrom,
    DateTime? nextVisit,
    required List<PrescriptionMedicineInput> existingMedicines,
  }) {
    tenureInDays = tenure.toString();
    doctorNotes = notes;
    continuedFromPrescriptionId = continuedFrom ?? '';
    nextVisitDate = nextVisit;
    medicines
      ..clear()
      ..addAll(
        existingMedicines.isEmpty
            ? [MedicineFormRow()]
            : existingMedicines.map(
                (m) => MedicineFormRow(
                  medicineId: m.medicineId,
                  customMedicineName: m.customMedicineName,
                  dosageAmount: m.dosageAmount,
                  frequency: m.frequency,
                  durationInDays: m.durationInDays.toString(),
                ),
              ),
      );
    _dirty = false;
    notifyListeners();
  }

  String? validate() {
    final tenure = int.tryParse(tenureInDays.trim());
    if (tenure == null || tenure <= 0) {
      return 'Enter a valid prescription tenure (days).';
    }
    if (medicines.isEmpty) {
      return 'Add at least one medicine.';
    }
    for (var i = 0; i < medicines.length; i++) {
      final m = medicines[i];
      if (m.customMedicineName.trim().isEmpty) {
        return 'Medicine ${i + 1}: name is required.';
      }
      if (m.dosageAmount.trim().isEmpty) {
        return 'Medicine ${i + 1}: dosage is required.';
      }
      if (m.frequency.trim().isEmpty) {
        return 'Medicine ${i + 1}: frequency is required.';
      }
      final days = int.tryParse(m.durationInDays.trim());
      if (days == null || days <= 0) {
        return 'Medicine ${i + 1}: enter a valid duration (days).';
      }
    }
    return null;
  }

  Future<void> submit({
    required String visitId,
    required String patientId,
    required String doctorId,
    required String bearerToken,
    String? prescriptionId,
  }) async {
    final err = validate();
    if (err != null) {
      formError = err;
      notifyListeners();
      throw ValidationFailure(err);
    }

    submitting = true;
    formError = null;
    notifyListeners();

    try {
      final medicineInputs = medicines
          .map(
            (m) => PrescriptionMedicineInput(
              medicineId: m.medicineId,
              customMedicineName: m.customMedicineName.trim(),
              dosageAmount: m.dosageAmount.trim(),
              frequency: m.frequency.trim(),
              durationInDays: int.parse(m.durationInDays.trim()),
            ),
          )
          .toList();

      final continued = continuedFromPrescriptionId.trim().isEmpty
          ? null
          : continuedFromPrescriptionId.trim();

      final rxId = prescriptionId?.trim();
      if (rxId != null && rxId.isNotEmpty) {
        await _api.updatePrescription(
          request: PrescriptionEditRequest(
            prescriptionId: rxId,
            doctorId: doctorId,
            tenureInDays: int.parse(tenureInDays.trim()),
            doctorNotes: doctorNotes.trim(),
            continuedFromPrescriptionId: continued,
            medicines: medicineInputs,
          ),
          bearerToken: bearerToken,
        );
      } else {
        await _api.createPrescription(
          request: PrescriptionSubmitRequest(
            visitId: visitId,
            patientId: patientId,
            doctorId: doctorId,
            tenureInDays: int.parse(tenureInDays.trim()),
            doctorNotes: doctorNotes.trim(),
            continuedFromPrescriptionId: continued,
            nextVisitDate: nextVisitDate,
            medicines: medicineInputs,
          ),
          bearerToken: bearerToken,
        );
      }
      _dirty = false;
    } catch (e) {
      if (e is! ApiFailure) {
        formError = _apiClient.mapError(e).message;
        notifyListeners();
        throw _apiClient.mapError(e);
      }
      formError = e.message;
      notifyListeners();
      rethrow;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}
