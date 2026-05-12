import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/endpoints.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';

class HealthWorkerDashboardApi {
  HealthWorkerDashboardApi(this._client);

  final ApiClient _client;

  Future<HwDashboardStats> getStats({
    required String healthWorkerId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.healthWorkerDashboardStats(healthWorkerId),
      bearerToken: bearerToken,
    );
    final parsed = HwDashboardStats.tryFromJson(res.data);
    if (parsed == null) {
      throw StateError('Invalid dashboard stats response.');
    }
    return parsed;
  }

  Future<List<HwFollowUpPatient>> getFollowUps({
    required String healthWorkerId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.healthWorkerDashboardFollowUps(healthWorkerId),
      bearerToken: bearerToken,
    );
    return _parseFollowUpList(res.data);
  }

  Future<List<HwPatientSummary>> getAllPatients({
    required String healthWorkerId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.healthWorkerDashboardPatients(healthWorkerId),
      bearerToken: bearerToken,
    );
    return _parsePatientSummaryList(res.data);
  }

  static List<HwFollowUpPatient> _parseFollowUpList(dynamic data) {
    if (data is! List) return const [];
    final out = <HwFollowUpPatient>[];
    for (final item in data) {
      final row = HwFollowUpPatient.tryFromJson(item);
      if (row != null) out.add(row);
    }
    return out;
  }

  static List<HwPatientSummary> _parsePatientSummaryList(dynamic data) {
    if (data is! List) return const [];
    final out = <HwPatientSummary>[];
    for (final item in data) {
      final row = HwPatientSummary.tryFromJson(item);
      if (row != null) out.add(row);
    }
    return out;
  }
}
