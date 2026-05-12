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

Map<String, dynamic>? _unwrapEnvelopeMap(dynamic root) {
  if (root is Map) {
    final m = Map<String, dynamic>.from(root);
    final inner = m['data'] ?? m['Data'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return m;
  }
  return null;
}

int? _parseCreatedIntId(dynamic root) {
  if (root is! Map) return null;
  final m = Map<String, dynamic>.from(root);
  final v = m['id'] ?? m['Id'];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
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

  /// Read-only: `GET /api/Patient/medicalhistory/{patientId}`.
  ///
  /// Returns an empty list on **404** (no rows yet, or some servers return
  /// "patient not found" for this route while other patient routes still work).
  Future<List<PatientMedicalHistoryRow>> getMedicalHistory({
    required String patientId,
    required String bearerToken,
  }) async {
    try {
      final res = await _client.get(
        Endpoints.patientMedicalHistory(patientId),
        bearerToken: bearerToken,
      );
      final raw = _unwrapEnvelopeList(res.data);
      final out = <PatientMedicalHistoryRow>[];
      for (final item in raw) {
        final row = PatientMedicalHistoryRow.tryFromJson(item);
        if (row != null) out.add(row);
      }
      return out;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// `PUT /api/PatientHistory/medical/{id}` — preferred for updates (matches `PatientHistoryController`).
  Future<void> patientHistoryUpdateMedical({
    required int recordId,
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    await _client.put(
      Endpoints.patientHistoryMedicalPut(recordId),
      body: body,
      bearerToken: bearerToken,
    );
  }

  /// `POST /api/PatientHistory/medical`.
  Future<int> patientHistoryCreateMedical({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.post(
      Endpoints.patientHistoryMedicalPost,
      body: body,
      bearerToken: bearerToken,
    );
    final id = _parseCreatedIntId(res.data);
    if (id == null) {
      throw StateError('Invalid medical history create response.');
    }
    return id;
  }

  /// `POST /api/PatientHistory/surgical`.
  Future<int> patientHistoryCreateSurgical({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.post(
      Endpoints.patientHistorySurgicalPost,
      body: body,
      bearerToken: bearerToken,
    );
    final id = _parseCreatedIntId(res.data);
    if (id == null) {
      throw StateError('Invalid surgical history create response.');
    }
    return id;
  }

  /// `POST /api/PatientHistory/drug`.
  Future<int> patientHistoryCreateDrug({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    final res = await _client.post(
      Endpoints.patientHistoryDrugPost,
      body: body,
      bearerToken: bearerToken,
    );
    final id = _parseCreatedIntId(res.data);
    if (id == null) {
      throw StateError('Invalid drug history create response.');
    }
    return id;
  }

  /// `POST /api/PatientHistory/lifestyle`, or `POST /api/Patient/baselinelifestyle`
  /// when the server returns **404** (deploy has `PatientController` only).
  Future<void> patientHistoryCreateLifestyle({
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    try {
      await _client.post(
        Endpoints.patientHistoryLifestylePost,
        body: body,
        bearerToken: bearerToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await _client.post(
          Endpoints.patientBaselineLifestyleUpsert,
          body: body,
          bearerToken: bearerToken,
        );
        return;
      }
      rethrow;
    }
  }

  /// `PUT /api/PatientHistory/lifestyle/{patientId}`, or `PUT /api/Patient/baselinelifestyle`
  /// when the server returns **404** (same as [patientHistoryCreateLifestyle]).
  Future<void> patientHistoryUpdateLifestyle({
    required String patientId,
    required Map<String, dynamic> body,
    required String bearerToken,
  }) async {
    try {
      await _client.put(
        Endpoints.patientHistoryLifestylePut(patientId),
        body: body,
        bearerToken: bearerToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await _client.put(
          Endpoints.patientBaselineLifestyleUpsert,
          body: body,
          bearerToken: bearerToken,
        );
        return;
      }
      rethrow;
    }
  }

  Future<List<PatientSurgicalHistoryRow>> getSurgicalHistory({
    required String patientId,
    required String bearerToken,
  }) async {
    try {
      final res = await _client.get(
        Endpoints.patientSurgicalHistory(patientId),
        bearerToken: bearerToken,
      );
      final raw = _unwrapEnvelopeList(res.data);
      final out = <PatientSurgicalHistoryRow>[];
      for (final item in raw) {
        final row = PatientSurgicalHistoryRow.tryFromJson(item);
        if (row != null) out.add(row);
      }
      return out;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<List<PatientDrugHistoryRow>> getDrugHistory({
    required String patientId,
    required String bearerToken,
  }) async {
    try {
      final res = await _client.get(
        Endpoints.patientDrugHistory(patientId),
        bearerToken: bearerToken,
      );
      final raw = _unwrapEnvelopeList(res.data);
      final out = <PatientDrugHistoryRow>[];
      for (final item in raw) {
        final row = PatientDrugHistoryRow.tryFromJson(item);
        if (row != null) out.add(row);
      }
      return out;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// Returns `null` when the server responds 404 (no baseline row yet).
  Future<PatientBaselineLifestyle?> getBaselineLifestyle({
    required String patientId,
    required String bearerToken,
  }) async {
    try {
      final res = await _client.get(
        Endpoints.patientBaselineLifestyle(patientId),
        bearerToken: bearerToken,
      );
      final m = _unwrapEnvelopeMap(res.data);
      if (m == null) return null;
      return PatientBaselineLifestyle.tryFromJson(m);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Visit list + upsert: `PatientController` (`PatientVisitResponseModel` rows).
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
}
