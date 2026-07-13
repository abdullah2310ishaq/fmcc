import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/reference/reference_api.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

class MedicineFormRow {
  MedicineFormRow({
    this.medicineId = 0,
    this.customMedicineName = '',
    this.dosageAmount = '',
    this.frequency = '',
    this.durationInDays = '',
    this.useCustomName = false,
  });

  int medicineId;
  String customMedicineName;
  String dosageAmount;
  String frequency;
  String durationInDays;

  /// When true, doctor typed a custom name ("Other") instead of picking a list item.
  bool useCustomName;
}

class PrescriptionFormController extends ChangeNotifier {
  PrescriptionFormController({
    required DoctorApi api,
    required ApiClient apiClient,
    ReferenceApi? referenceApi,
  })  : _api = api,
        _apiClient = apiClient,
        _referenceApi = referenceApi ?? ReferenceApi(apiClient);

  final DoctorApi _api;
  final ApiClient _apiClient;
  final ReferenceApi _referenceApi;

  final List<MedicineFormRow> medicines = [MedicineFormRow()];

  List<ActiveMedicine> activeMedicines = const [];
  bool loadingMedicines = false;
  String? medicinesLoadError;

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

  Future<void> loadActiveMedicines(String bearerToken) async {
    if (bearerToken.trim().isEmpty) return;
    loadingMedicines = true;
    medicinesLoadError = null;
    notifyListeners();
    try {
      activeMedicines = await _referenceApi.getActiveMedicines(
        bearerToken: bearerToken,
      );
      _reconcileRowsWithCatalog();
    } catch (e) {
      medicinesLoadError = e is ApiFailure
          ? e.message
          : _apiClient.mapError(e).message;
    } finally {
      loadingMedicines = false;
      notifyListeners();
    }
  }

  void _reconcileRowsWithCatalog() {
    if (activeMedicines.isEmpty) return;
    for (final m in medicines) {
      if (m.useCustomName) continue;
      ActiveMedicine? match;
      if (m.medicineId > 0) {
        for (final e in activeMedicines) {
          if (e.medicineId == m.medicineId) {
            match = e;
            break;
          }
        }
      }
      if (match == null) {
        final name = m.customMedicineName.trim().toLowerCase();
        if (name.isNotEmpty) {
          for (final e in activeMedicines) {
            if (e.medicineName.trim().toLowerCase() == name) {
              match = e;
              break;
            }
          }
        }
      }
      if (match != null) {
        m.medicineId = match.medicineId;
        m.customMedicineName = match.medicineName;
        m.useCustomName = false;
      } else if (m.customMedicineName.trim().isNotEmpty) {
        m.medicineId = 0;
        m.useCustomName = true;
      }
    }
  }

  void selectMedicine(int index, ActiveMedicine medicine) {
    if (index < 0 || index >= medicines.length) return;
    final m = medicines[index];
    m.medicineId = medicine.medicineId;
    m.customMedicineName = medicine.medicineName;
    m.useCustomName = false;
    markDirty();
    notifyListeners();
  }

  void selectOtherMedicine(int index) {
    if (index < 0 || index >= medicines.length) return;
    final m = medicines[index];
    m.medicineId = 0;
    m.customMedicineName = '';
    m.useCustomName = true;
    markDirty();
    notifyListeners();
  }

  void setCustomMedicineName(int index, String value) {
    if (index < 0 || index >= medicines.length) return;
    final m = medicines[index];
    m.customMedicineName = value;
    m.medicineId = 0;
    m.useCustomName = true;
    markDirty();
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
                  useCustomName: m.medicineId <= 0,
                ),
              ),
      );
    _reconcileRowsWithCatalog();
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
      if (!m.useCustomName && m.medicineId <= 0 && m.customMedicineName.trim().isEmpty) {
        return 'Medicine ${i + 1}: select a medicine.';
      }
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
              medicineId: m.useCustomName ? 0 : m.medicineId,
              customMedicineName: m.customMedicineName.trim(),
              dosageAmount: m.dosageAmount.trim(),
              frequency: m.frequency.trim(),
              durationInDays: int.parse(m.durationInDays.trim()),
            ),
          )
          .toList();

      final rxId = prescriptionId?.trim();
      if (rxId != null && rxId.isNotEmpty) {
        await _api.updatePrescription(
          request: PrescriptionEditRequest(
            prescriptionId: rxId,
            doctorId: doctorId,
            tenureInDays: int.parse(tenureInDays.trim()),
            doctorNotes: doctorNotes.trim(),
            continuedFromPrescriptionId: null,
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
            continuedFromPrescriptionId: null,
            nextVisitDate: null,
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
