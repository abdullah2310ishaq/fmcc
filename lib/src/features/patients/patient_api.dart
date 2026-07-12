import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/endpoints.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';
import 'package:doctor_app/src/features/visits/visit_instruction_models.dart';

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

int? _relativeIdFromMap(Map<String, dynamic> map) {
  const keys = <String>[
    'relativeId',
    'RelativeId',
    'id',
    'Id',
  ];
  for (final k in keys) {
    final v = map[k];
    if (v is int && v > 0) return v;
    if (v is num) {
      final i = v.toInt();
      if (i > 0) return i;
    }
    if (v is String) {
      final i = int.tryParse(v.trim());
      if (i != null && i > 0) return i;
    }
  }
  return null;
}

int? _parseRelativeId(dynamic root) {
  if (root is int && root > 0) return root;
  if (root is num) {
    final i = root.toInt();
    if (i > 0) return i;
  }
  if (root is String) {
    final i = int.tryParse(root.trim());
    if (i != null && i > 0) return i;
  }
  if (root is! Map) return null;
  final m = Map<String, dynamic>.from(root);

  final fromRoot = _relativeIdFromMap(m);
  if (fromRoot != null) return fromRoot;

  final rawData = m['data'] ?? m['Data'];
  if (rawData is int && rawData > 0) return rawData;
  if (rawData is num) {
    final i = rawData.toInt();
    if (i > 0) return i;
  }
  if (rawData is String) {
    final i = int.tryParse(rawData.trim());
    if (i != null && i > 0) return i;
  }
  if (rawData is Map) {
    return _relativeIdFromMap(Map<String, dynamic>.from(rawData));
  }
  return null;
}

int? _parseCreatedRowId(dynamic root) => _parseRelativeId(root);

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
  /// `baselineLifestyle`, `patientLifeStyle` per API model).
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
  Future<int> postMedicalHistory({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.post(
      Endpoints.patientMedicalHistoryUpsert,
      body: body,
      bearerToken: bearerToken,
    );
    final id = _parseCreatedRowId(res.data);
    if (id == null) {
      throw StateError('Invalid create medical history response.');
    }
    return id;
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
  Future<int> postSurgicalHistory({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.post(
      Endpoints.patientSurgicalHistoryUpsert,
      body: body,
      bearerToken: bearerToken,
    );
    final id = _parseCreatedRowId(res.data);
    if (id == null) {
      throw StateError('Invalid create surgical history response.');
    }
    return id;
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
  Future<int> postDrugHistory({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.post(
      Endpoints.patientDrugHistoryUpsert,
      body: body,
      bearerToken: bearerToken,
    );
    final id = _parseCreatedRowId(res.data);
    if (id == null) {
      throw StateError('Invalid create drug history response.');
    }
    return id;
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

  /// `GET /api/Patient/familyhistory/{patientId}`.
  Future<PatientFamilyHistoryData?> getFamilyHistory({
    required String patientId,
    required String bearerToken,
  }) async {
    final path = Endpoints.patientFamilyHistory(patientId);
    try {
      final res = await _client.get(
        path,
        bearerToken: bearerToken,
      );
      try {
        final pretty = const JsonEncoder.withIndent('  ').convert(res.data);
        AppLogger.instance.i('[PatientApi] RAW GET $path\n$pretty');
      } catch (_) {
        AppLogger.instance.i('[PatientApi] RAW GET $path\n${res.data}');
      }
      final parsed = PatientFamilyHistoryData.tryFromJson(res.data);
      AppLogger.instance.i(
        '[PatientApi] PARSED GET $path → ${parsed?.relatives.length ?? 0} relative(s)',
      );
      return parsed;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.instance.i('[PatientApi] GET $path → 404 (no family history yet)');
        return const PatientFamilyHistoryData(relatives: []);
      }
      rethrow;
    }
  }

  /// `POST /api/Patient/familyhistory/relative` — returns new relative id.
  Future<int> postFamilyRelative({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.post(
      Endpoints.patientFamilyRelativeCreate,
      body: body,
      bearerToken: bearerToken,
    );
    final id = _parseRelativeId(res.data);
    if (id == null) {
      throw StateError('Invalid create family relative response.');
    }
    return id;
  }

  /// `POST /api/Patient/familyhistory/relative/{relativeId}/conditions`.
  Future<void> postFamilyRelativeConditions({
    required int relativeId,
    required List<Map<String, dynamic>> body,
    required String bearerToken,
  }) async {
    if (body.isEmpty) return;
    await _client.post(
      Endpoints.patientFamilyRelativeConditions(relativeId),
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `DELETE /api/Patient/familyhistory/relative/{patientId}/{relativeId}`.
  Future<void> deleteFamilyRelative({
    required String patientId,
    required int relativeId,
    required String bearerToken,
  }) async {
    await _client.delete(
      Endpoints.patientFamilyRelativeDelete(patientId, relativeId),
      bearerToken: bearerToken,
    );
  }

  /// `DELETE /api/Patient/familyhistory/condition/{patientId}/{relativeConditionId}`.
  Future<void> deleteFamilyCondition({
    required String patientId,
    required String relativeConditionId,
    required String bearerToken,
  }) async {
    await _client.delete(
      Endpoints.patientFamilyConditionDelete(patientId, relativeConditionId),
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

  /// `GET /api/Patient/lifestyle/{patientId}`.
  Future<PatientLifeStyle?> getLifestyle({
    required String patientId,
    required String bearerToken,
  }) async {
    try {
      final res = await _client.get(
        Endpoints.patientLifestyle(patientId),
        bearerToken: bearerToken,
      );
      final data = res.data;
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        final inner = m['data'] ?? m['Data'];
        if (inner is Map) {
          return PatientLifeStyle.tryFromJson(inner);
        }
        return PatientLifeStyle.tryFromJson(m);
      }
      return PatientLifeStyle.tryFromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// `PUT /api/Patient/lifestyle` — create or update lifestyle.
  Future<void> upsertLifestyle({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.put(
      Endpoints.patientLifestyleUpsert,
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `GET /api/Patient/instructions` — pre-visit instruction carousel.
  Future<List<VisitInstruction>> getVisitInstructions({
    required String bearerToken,
  }) async {
    try {
      final res = await _client.get(
        Endpoints.patientVisitInstructions,
        bearerToken: bearerToken,
      );
      return parseVisitInstructionsList(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// `GET /api/Patient/counselling-instructison` — text-only list for Controlled BP.
  Future<List<CounsellingInstruction>> getCounsellingInstructions({
    required String bearerToken,
  }) async {
    final res = await _client.get(
      Endpoints.patientCounsellingInstructions,
      bearerToken: bearerToken,
    );
    return parseCounsellingInstructionsList(res.data);
  }
}
