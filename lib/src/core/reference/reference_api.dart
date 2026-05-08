import 'dart:convert';

import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/network/endpoints.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';

class ReferenceApi {
  ReferenceApi(this._client);

  final ApiClient _client;

  Future<List<EducationLevel>> getEducationLevels({required String bearerToken}) async {
    final path = Endpoints.educationLevels;
    final res = await _client.get(
      path,
      bearerToken: bearerToken,
    );
    final data = res.data;
    _logReferenceRaw(path, data);
    final parsed = _parseList(data, EducationLevel.fromJson);
    _logParsedSummary(path, parsed.length, parsed.map((e) => {'id': e.id, 'name': e.name}).toList());
    return parsed;
  }

  Future<List<Province>> getProvinces({required String bearerToken}) async {
    final path = Endpoints.provinces;
    final res = await _client.get(
      path,
      bearerToken: bearerToken,
    );
    final data = res.data;
    _logReferenceRaw(path, data);
    final parsed = _parseList(data, Province.fromJson);
    _logParsedSummary(path, parsed.length, parsed.map((e) => {'id': e.id, 'name': e.name}).toList());
    return parsed;
  }

  Future<List<District>> getDistricts({
    required int provinceId,
    required String bearerToken,
  }) async {
    final path = Endpoints.districts(provinceId);
    final res = await _client.get(
      path,
      bearerToken: bearerToken,
    );
    final data = res.data;
    _logReferenceRaw(path, data);
    final parsed = _parseList(data, District.fromJson);
    _logParsedSummary(path, parsed.length, parsed.map((e) => {'id': e.id, 'name': e.name}).toList());
    return parsed;
  }

  Future<List<Tehsil>> getTehsils({
    required int provinceId,
    required int districtId,
    required String bearerToken,
  }) async {
    final path = Endpoints.tehsils(provinceId, districtId);
    final res = await _client.get(
      path,
      bearerToken: bearerToken,
    );
    final data = res.data;
    _logReferenceRaw(path, data);
    final parsed = _parseList(data, Tehsil.fromJson);
    _logParsedSummary(path, parsed.length, parsed.map((e) => {'id': e.id, 'name': e.name}).toList());
    return parsed;
  }

  static void _logReferenceRaw(String path, dynamic data) {
    try {
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      AppLogger.instance.i('[ReferenceAPI] RAW GET $path\n$pretty');
    } catch (_) {
      AppLogger.instance.i('[ReferenceAPI] RAW GET $path\n$data');
    }
  }

  static void _logParsedSummary(
    String path,
    int count,
    List<Map<String, Object>> rows,
  ) {
    try {
      final pretty = const JsonEncoder.withIndent('  ').convert(rows);
      AppLogger.instance.i(
        '[ReferenceAPI] PARSED GET $path → $count rows\n$pretty',
      );
    } catch (_) {
      AppLogger.instance.i('[ReferenceAPI] PARSED GET $path → $count rows');
    }
  }

  static List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (data is List) {
      return _mapList(data, fromJson);
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      const keys = [
        'data',
        'Data',
        'result',
        'Result',
        'items',
        'Items',
        'records',
        'Records',
        'value',
        'Value',
        'content',
        'Content',
      ];
      for (final k in keys) {
        final inner = map[k];
        if (inner is List) {
          return _mapList(inner, fromJson);
        }
      }
    }
    return const [];
  }

  static List<T> _mapList<T>(
    List<dynamic> list,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final out = <T>[];
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        try {
          out.add(fromJson(e));
        } catch (_) {}
      } else if (e is Map) {
        try {
          out.add(fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }
    return List<T>.unmodifiable(out);
  }
}

