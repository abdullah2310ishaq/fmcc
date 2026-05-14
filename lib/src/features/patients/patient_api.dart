import 'package:dio/dio.dart';

import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/endpoints.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';

List<dynamic> _unwrapEnvelopeList(dynamic root) {
  if (root is List) return root;
  if (root is Map) {
    final m = Map<String, dynamic>.from(root);
    final inner = m['data'] ?? m['Data'];
    if (inner is List) return inner;
  }
  return const [];
}

String? _visitIdFromMap(Map<String, dynamic> map) {
  const keys = <String>[
    'visitId',
    'VisitId',
    'visit_id',
    'Visit_Id',
    'id',
    'Id',
  ];
  for (final k in keys) {
    final v = map[k];
    if (v is String) {
      final t = v.trim();
      if (t.isNotEmpty) return t;
    } else if (v != null) {
      final t = v.toString().trim();
      if (t.isNotEmpty) return t;
    }
  }
  return null;
}

/// Accepts common API shapes for `POST/PUT …/Patient/visit` responses.
String? _parseVisitId(dynamic root) {
  if (root is String) {
    final t = root.trim();
    return t.isEmpty ? null : t;
  }
  if (root is! Map) return null;
  final m = Map<String, dynamic>.from(root);

  final rawData = m['data'] ?? m['Data'];
  if (rawData is String) {
    final t = rawData.trim();
    if (t.isNotEmpty) return t;
  }
  if (rawData is Map) {
    final fromData = _visitIdFromMap(Map<String, dynamic>.from(rawData));
    if (fromData != null) return fromData;
  }

  final rawResult = m['result'] ?? m['Result'];
  if (rawResult is String) {
    final t = rawResult.trim();
    if (t.isNotEmpty) return t;
  }
  if (rawResult is Map) {
    final fromResult = _visitIdFromMap(Map<String, dynamic>.from(rawResult));
    if (fromResult != null) return fromResult;
  }

  return _visitIdFromMap(m);
}

/// Patient HTTP API — mirrors `MedicalApi/Controllers/PatientController.cs`.
///
/// **Bundled read:** [getCompleteHistory] calls
/// `GET /api/Patient/complete-history/{patientId}` and maps one payload to
/// baseline lifestyle plus **medical**, **surgical**, and **drug** history lists.
///
/// **Writes:** create and update are **different methods** on the same paths:
/// - `POST …/medicalhistory` — body **without** row `id` (create).
/// - `PUT …/medicalhistory` — body **with** row `id` (update).
/// Same pattern for `surgicalhistory`, `drughistory`, and `baselinelifestyle`.
///
/// **Deletes:** `DELETE …/medicalhistory/{id}`, `DELETE …/surgicalhistory/{id}`,
/// `DELETE …/drughistory/{id}`.
class PatientApi {
  PatientApi(this._client);

  final ApiClient _client;

  Future<PatientUpsertResult> createPatient({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.post(
      Endpoints.patientCreate,
      body: body,
      bearerToken: bearerToken,
    );
    final parsed = PatientUpsertResult.tryParse(res.data);
    if (parsed == null) {
      throw StateError('Invalid create patient response.');
    }
    return parsed;
  }

  Future<PatientUpsertResult> updatePatient({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.put(
      Endpoints.patientUpdate,
      body: body,
      bearerToken: bearerToken,
    );
    final parsed = PatientUpsertResult.tryParse(res.data);
    if (parsed == null) {
      throw StateError('Invalid update patient response.');
    }
    return parsed;
  }

  /// `GET /api/Patient/{patientId}` — bare [PatientProfileResponseModel].
  Future<PatientProfileData> getPatientProfile({
    required String patientId,
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.patientById(patientId),
      bearerToken: bearerToken,
    );
    final parsed = PatientProfileData.tryFromJson(res.data);
    if (parsed == null) {
      throw StateError('Invalid patient profile response.');
    }
    return parsed;
  }

  /// `GET /api/Patient/complete-history/{patientId}` — aggregate
  /// [PatientCompleteHistoryData] (`medicalHistory`, `surgicalHistory`, `drugHistory`,
  /// `baselineLifestyle` per API model).
  ///
  /// Returns `null` on **404** (controller requires all four parts present).
  Future<PatientCompleteHistoryData?> getCompleteHistory({
    required String patientId,
    required String bearerToken,
  }) async {
    try {
      final res = await _client.get(
        Endpoints.patientCompleteHistory(patientId),
        bearerToken: bearerToken,
      );
      return PatientCompleteHistoryData.tryFromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Visit list: `GET /api/Patient/visits/{patientId}/` → `{ message, data }`.
  Future<List<PatientVisitRow>> getVisits({
    required String patientId,
    required String bearerToken,
  }) async {
    try {
      final res = await _client.get(
        Endpoints.patientVisits(patientId),
        bearerToken: bearerToken,
      );
      final raw = _unwrapEnvelopeList(res.data);
      final out = <PatientVisitRow>[];
      for (final item in raw) {
        final row = PatientVisitRow.tryFromJson(item);
        if (row != null) out.add(row);
      }
      return out;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// `POST /api/Patient/visit` — returns new visit id string.
  Future<String> createVisit({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.post(
      Endpoints.patientVisitCreate,
      body: body,
      bearerToken: bearerToken,
    );
    final id = _parseVisitId(res.data);
    if (id == null || id.isEmpty) {
      throw StateError('Invalid create visit response.');
    }
    return id;
  }

  /// `PUT /api/Patient/visit` — returns visit id string.
  Future<String> updateVisit({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.put(
      Endpoints.patientVisitUpdate,
      body: body,
      bearerToken: bearerToken,
    );
    final id = _parseVisitId(res.data);
    if (id == null || id.isEmpty) {
      throw StateError('Invalid update visit response.');
    }
    return id;
  }

  /// `PUT /api/Patient/medicalhistory` — update [PatientMedicalHistoryModel] (requires `id`).
  Future<void> putMedicalHistory({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.put(
      Endpoints.patientMedicalHistoryUpsert,
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `POST /api/Patient/medicalhistory` — create row (`id` omitted).
  Future<void> postMedicalHistory({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.post(
      Endpoints.patientMedicalHistoryUpsert,
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `PUT /api/Patient/surgicalhistory` — update row (**requires** `id` in body).
  Future<void> putSurgicalHistory({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.put(
      Endpoints.patientSurgicalHistoryUpsert,
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `POST /api/Patient/surgicalhistory` — create row.
  Future<void> postSurgicalHistory({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.post(
      Endpoints.patientSurgicalHistoryUpsert,
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `PUT /api/Patient/drughistory` — update row (**requires** `id` in body).
  Future<void> putDrugHistory({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.put(
      Endpoints.patientDrugHistoryUpsert,
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `POST /api/Patient/drughistory` — create row.
  Future<void> postDrugHistory({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.post(
      Endpoints.patientDrugHistoryUpsert,
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `DELETE /api/Patient/medicalhistory/{id}`.
  Future<void> deleteMedicalHistory({
    required int id,
    required String bearerToken,
  }) async {
    await _client.delete(
      Endpoints.patientMedicalHistoryDelete(id),
      bearerToken: bearerToken,
    );
  }

  /// `DELETE /api/Patient/surgicalhistory/{id}`.
  Future<void> deleteSurgicalHistory({
    required int id,
    required String bearerToken,
  }) async {
    await _client.delete(
      Endpoints.patientSurgicalHistoryDelete(id),
      bearerToken: bearerToken,
    );
  }

  /// `DELETE /api/Patient/drughistory/{id}`.
  Future<void> deleteDrugHistory({
    required int id,
    required String bearerToken,
  }) async {
    await _client.delete(
      Endpoints.patientDrugHistoryDelete(id),
      bearerToken: bearerToken,
    );
  }

  /// `PUT /api/Patient/baselinelifestyle` — [PatientBaselineLifestyleModel].
  Future<void> putBaselineLifestyle({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.put(
      Endpoints.patientBaselineLifestyleUpsert,
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `POST /api/Patient/baselinelifestyle` — first baseline row.
  Future<void> postBaselineLifestyle({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.post(
      Endpoints.patientBaselineLifestyleUpsert,
      body: body,
      bearerToken: bearerToken,
    );
  }
}
