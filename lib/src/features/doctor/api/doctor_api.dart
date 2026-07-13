import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/endpoints.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

class DoctorApi {
  DoctorApi(this._client);

  final ApiClient _client;

  Future<void> unassignHospital({
    required String doctorId,
    required String bearerToken,
  }) async {
    await _client.post(
      Endpoints.doctorUnassignHospital(doctorId),
      bearerToken: bearerToken,
    );
  }

  Future<DoctorDashboardStats> getDashboard({
    required String doctorId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.doctorDashboard(doctorId),
      bearerToken: bearerToken,
    );
    final parsed = DoctorDashboardStats.tryFromJson(res.data);
    if (parsed == null) {
      throw StateError('Invalid doctor dashboard response.');
    }
    return parsed;
  }

  Future<List<DoctorQueuePatient>> getEmergencyQueue({
    required String doctorId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.doctorEmergencyQueue(doctorId),
      bearerToken: bearerToken,
    );
    return _parseQueue(unwrapListPayload(res.data));
  }

  Future<void> upsertPrescription({
    required UpsertPrescriptionRequest request,
    required String bearerToken,
  }) async {
    await _client.put(
      Endpoints.doctorPrescription,
      body: request.toJson(),
      bearerToken: bearerToken,
    );
  }

  Future<List<DoctorPrescriptionSummary>> getDoctorPrescriptions({
    required String doctorId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.doctorPrescriptions(doctorId),
      bearerToken: bearerToken,
    );
    return _parseDoctorPrescriptions(unwrapListPayload(res.data));
  }

  Future<List<PatientPrescriptionHistoryItem>> getPatientPrescriptionHistory({
    required String patientId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.patientPrescriptionHistory(patientId),
      bearerToken: bearerToken,
    );
    return _parsePatientPrescriptionHistory(unwrapListPayload(res.data));
  }

  static List<DoctorQueuePatient> _parseQueue(dynamic data) {
    if (data is! List) return const [];
    final out = <DoctorQueuePatient>[];
    for (final item in data) {
      final row = DoctorQueuePatient.tryFromJson(item);
      if (row != null) out.add(row);
    }
    return out;
  }

  static List<DoctorPrescriptionSummary> _parseDoctorPrescriptions(
    dynamic data,
  ) {
    if (data is! List) return const [];
    final out = <DoctorPrescriptionSummary>[];
    for (final item in data) {
      final row = DoctorPrescriptionSummary.tryFromJson(item);
      if (row != null) out.add(row);
    }
    return out;
  }

  static List<PatientPrescriptionHistoryItem> _parsePatientPrescriptionHistory(
    dynamic data,
  ) {
    if (data is! List) return const [];
    final out = <PatientPrescriptionHistoryItem>[];
    for (final item in data) {
      final row = PatientPrescriptionHistoryItem.tryFromJson(item);
      if (row != null) out.add(row);
    }
    return out;
  }
}
