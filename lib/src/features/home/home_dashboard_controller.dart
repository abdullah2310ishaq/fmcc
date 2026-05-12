import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_api.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';

/// Loads Health Worker dashboard payloads (`stats`, `followups`, `patients`).
class HomeDashboardController extends ChangeNotifier {
  HomeDashboardController({
    required HealthWorkerDashboardApi api,
    required ApiClient apiClient,
  })  : _api = api,
        _apiClient = apiClient;

  final HealthWorkerDashboardApi _api;
  final ApiClient _apiClient;

  HwDashboardStats? _stats;
  List<HwFollowUpPatient> _followUps = const [];
  List<HwPatientSummary> _patients = const [];
  bool _loading = false;
  String? _error;

  HwDashboardStats? get stats => _stats;
  List<HwFollowUpPatient> get followUps => _followUps;
  List<HwPatientSummary> get patients => _patients;
  bool get loading => _loading;
  String? get error => _error;

  /// Last successful load had usable dashboard payloads.
  bool get hasData =>
      _stats != null || _followUps.isNotEmpty || _patients.isNotEmpty;

  Future<void> refreshFromSession(AppSession session) async {
    if (session.role != UserRole.ladyHealthWorker) {
      _stats = null;
      _followUps = const [];
      _patients = const [];
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final token = session.accessToken?.trim();
    final hwId = session.userId?.trim();
    if (token == null ||
        token.isEmpty ||
        hwId == null ||
        hwId.isEmpty) {
      _stats = null;
      _followUps = const [];
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
      final results = await Future.wait([
        _api.getStats(healthWorkerId: hwId, bearerToken: token),
        _api.getFollowUps(healthWorkerId: hwId, bearerToken: token),
        _api.getAllPatients(healthWorkerId: hwId, bearerToken: token),
      ]);

      _stats = results[0] as HwDashboardStats;
      _followUps = results[1] as List<HwFollowUpPatient>;
      _patients = results[2] as List<HwPatientSummary>;
      _error = null;
    } catch (e) {
      _error = _apiClient.mapError(e).message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
