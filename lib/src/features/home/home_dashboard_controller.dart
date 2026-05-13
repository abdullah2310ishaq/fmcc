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

  /// Removes [patientId] from the in-memory follow-up queue (e.g. after saving a
  /// follow-up visit with a terminal status). The next [refreshFromSession] may
  /// repopulate from the API if the backend still returns this row.
  void removeFollowUpForPatient(String patientId) {
    final key = patientId.trim().toLowerCase();
    if (key.isEmpty) return;
    final filtered = _followUps
        .where((f) => f.patientId.trim().toLowerCase() != key)
        .toList();
    if (filtered.length == _followUps.length) return;
    _followUps = filtered;
    notifyListeners();
  }

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
    final hwId = session.healthWorkerIdForPatientApis?.trim();
    if (token == null || token.isEmpty || hwId == null || hwId.isEmpty) {
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

    final errors = <String>[];

    Future<void> loadStats() async {
      try {
        _stats = await _api.getStats(
          healthWorkerId: hwId,
          bearerToken: token,
        );
      } catch (e) {
        _stats = null;
        errors.add(_apiClient.mapError(e).message);
      }
    }

    Future<void> loadFollowUps() async {
      try {
        _followUps = await _api.getFollowUps(
          healthWorkerId: hwId,
          bearerToken: token,
        );
      } catch (e) {
        _followUps = const [];
        errors.add(_apiClient.mapError(e).message);
      }
    }

    Future<void> loadPatients() async {
      try {
        _patients = await _api.getAllPatients(
          healthWorkerId: hwId,
          bearerToken: token,
        );
      } catch (e) {
        _patients = const [];
        errors.add(_apiClient.mapError(e).message);
      }
    }

    await Future.wait([
      loadStats(),
      loadFollowUps(),
      loadPatients(),
    ]);
    _error = errors.isEmpty ? null : errors.join('\n');

    _loading = false;
    notifyListeners();
  }
}
