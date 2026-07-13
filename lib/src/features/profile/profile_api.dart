import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/endpoints.dart';
import 'package:doctor_app/src/features/profile/doctor_profile_models.dart';
import 'package:doctor_app/src/features/profile/health_worker_profile_models.dart';

class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  Future<DoctorProfile?> getDoctorProfile({
    required String userId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.doctorProfileGet(userId),
      bearerToken: bearerToken,
    );
    return DoctorProfile.tryFromApi(res.data);
  }

  Future<HealthWorkerProfile?> getHealthWorkerProfile({
    required String userId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.healthWorkerProfileGet(userId),
      bearerToken: bearerToken,
    );

    final dynamic data = res.data;
    if (data is Map) {
      final inner = data['data'] ?? data['Data'] ?? data['result'] ?? data['Result'] ?? data;
      final parsed = HealthWorkerProfile.tryFromApi(inner);
      if (parsed != null) return parsed;
    }

    return HealthWorkerProfile.tryFromApi(data);
  }

  Future<void> upsertHealthWorkerProfile({
    required HealthWorkerProfileUpsert profile,
    required String bearerToken,
  }) async {
    await _client.put(
      Endpoints.healthWorkerProfilePut,
      body: profile.toJson(),
      bearerToken: bearerToken,
    );
  }
}

