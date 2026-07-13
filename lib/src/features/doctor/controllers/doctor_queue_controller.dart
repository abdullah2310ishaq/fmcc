import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

class DoctorQueueController extends ChangeNotifier {
  DoctorQueueController({
    required DoctorApi api,
    required ApiClient apiClient,
  })  : _api = api,
        _apiClient = apiClient;

  final DoctorApi _api;
  final ApiClient _apiClient;

  List<DoctorQueuePatient> _patients = const [];
  bool _loading = false;
  String? _error;

  List<DoctorQueuePatient> get patients => _patients;
  bool get loading => _loading;
  String? get error => _error;

  /// Counts from queue API rows (`visitActionId` per patient).
  int get emergencyCount => _patients.where((p) => p.isEmergency).length;

  int get normalCount => _patients.where((p) => p.isNormal).length;

  List<DoctorQueuePatient> get emergencyPatients =>
      _patients.where((p) => p.isEmergency).toList();

  Future<void> refreshFromSession(AppSession session) async {
    if (session.role != UserRole.doctor) {
      _patients = const [];
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final token = session.accessToken?.trim();
    final doctorId = session.doctorIdForApis;
    if (token == null || token.isEmpty || doctorId.isEmpty) {
      _patients = const [];
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _patients = await _api.getEmergencyQueue(
        doctorId: doctorId,
        bearerToken: token,
      );
    } catch (e) {
      _patients = const [];
      _error = _apiClient.mapError(e).message;
    }

    _loading = false;
    notifyListeners();
  }
}
