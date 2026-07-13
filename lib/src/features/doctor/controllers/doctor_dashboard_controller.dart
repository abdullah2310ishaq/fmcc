import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

class DoctorDashboardController extends ChangeNotifier {
  DoctorDashboardController({
    required DoctorApi api,
    required ApiClient apiClient,
  })  : _api = api,
        _apiClient = apiClient;

  final DoctorApi _api;
  final ApiClient _apiClient;

  DoctorDashboardStats? _stats;
  bool _loading = false;
  String? _error;

  DoctorDashboardStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> refreshFromSession(AppSession session) async {
    if (session.role != UserRole.doctor) {
      _stats = null;
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final token = session.accessToken?.trim();
    final doctorId = session.doctorIdForApis;
    if (token == null || token.isEmpty || doctorId.isEmpty) {
      _stats = null;
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _api.getDashboard(
        doctorId: doctorId,
        bearerToken: token,
      );
    } catch (e) {
      _stats = null;
      _error = _apiClient.mapError(e).message;
    }

    _loading = false;
    notifyListeners();
  }
}
